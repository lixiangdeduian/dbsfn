-- =========================
-- 例程：住院与床位分配（包含游标示例）
-- =========================

-- 功能：为患者创建住院就诊（encounter=INPATIENT）与入院记录（admission），并可自动分配床位。
-- 说明：当未指定 bed_id 时，使用游标遍历候选床位并选择当前未被占用的床位；床位时间段冲突由触发器 trg_bed_assignment_bi_no_overlap 兜底。
DROP PROCEDURE IF EXISTS sp_inpatient_admit$$
CREATE PROCEDURE sp_inpatient_admit(
  IN p_patient_id BIGINT UNSIGNED,
  IN p_department_id BIGINT UNSIGNED,
  IN p_attending_doctor_id BIGINT UNSIGNED,
  IN p_ward_id BIGINT UNSIGNED,
  IN p_bed_id BIGINT UNSIGNED,
  IN p_note VARCHAR(1000),
  OUT o_encounter_id BIGINT UNSIGNED,
  OUT o_encounter_no VARCHAR(40),
  OUT o_admission_id BIGINT UNSIGNED,
  OUT o_admission_no VARCHAR(40),
  OUT o_bed_assignment_id BIGINT UNSIGNED,
  OUT o_assigned_bed_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_now DATETIME(3);
  DECLARE v_bed_id BIGINT UNSIGNED;
  DECLARE v_done TINYINT(1) DEFAULT 0;
  DECLARE v_cnt INT DEFAULT 0;

  -- 游标：遍历候选床位（按 ward_id 过滤，bed.status='AVAILABLE'，并锁定候选 bed 行）
  DECLARE cur_candidate_beds CURSOR FOR
    SELECT b.bed_id
    FROM bed b
    WHERE b.status = 'AVAILABLE'
      AND (p_ward_id IS NULL OR b.ward_id = p_ward_id)
    ORDER BY b.ward_id, b.bed_id
    FOR UPDATE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_patient_id IS NULL OR p_department_id IS NULL OR p_attending_doctor_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient_id/department_id/attending_doctor_id are required';
  END IF;

  SET v_now = CURRENT_TIMESTAMP(3);

  START TRANSACTION;

  IF NOT EXISTS (
    SELECT 1 FROM patient p WHERE p.patient_id = p_patient_id AND p.is_active = 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient not found or inactive';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM department d WHERE d.department_id = p_department_id AND d.is_active = 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'department not found or inactive';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM staff s WHERE s.staff_id = p_attending_doctor_id AND s.is_active = 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'attending_doctor not found or inactive';
  END IF;

  IF p_ward_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM ward w WHERE w.ward_id = p_ward_id AND w.is_active = 1
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ward not found or inactive';
    END IF;
  END IF;

  SET o_encounter_no = CONCAT('enc_', UUID_SHORT());
  INSERT INTO encounter (
    encounter_no,
    patient_id,
    department_id,
    doctor_id,
    registration_id,
    encounter_type,
    status,
    note
  )
  VALUES (
    o_encounter_no,
    p_patient_id,
    p_department_id,
    p_attending_doctor_id,
    NULL,
    'INPATIENT',
    'OPEN',
    p_note
  );
  SET o_encounter_id = LAST_INSERT_ID();

  SET o_admission_no = CONCAT('adm_', UUID_SHORT());
  INSERT INTO admission (
    admission_no,
    patient_id,
    department_id,
    attending_doctor_id,
    admitted_at,
    status,
    note
  )
  VALUES (
    o_admission_no,
    p_patient_id,
    p_department_id,
    p_attending_doctor_id,
    v_now,
    'ADMITTED',
    p_note
  );
  SET o_admission_id = LAST_INSERT_ID();

  SET o_bed_assignment_id = NULL;
  SET o_assigned_bed_id = NULL;

  IF p_bed_id IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM bed b
    WHERE b.bed_id = p_bed_id
      AND b.status = 'AVAILABLE'
      AND (p_ward_id IS NULL OR b.ward_id = p_ward_id)
    FOR UPDATE;

    IF v_cnt = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'bed not found/available or not in ward';
    END IF;

    INSERT INTO bed_assignment (
      admission_id,
      bed_id,
      start_at,
      end_at,
      note
    )
    VALUES (
      o_admission_id,
      p_bed_id,
      v_now,
      NULL,
      p_note
    );

    SET o_bed_assignment_id = LAST_INSERT_ID();
    SET o_assigned_bed_id = p_bed_id;
  ELSE
    OPEN cur_candidate_beds;
    bed_loop: LOOP
      FETCH cur_candidate_beds INTO v_bed_id;
      IF v_done = 1 THEN
        LEAVE bed_loop;
      END IF;

      -- 说明：在尝试插入前锁定当前床位相关的占用记录，降低并发下的冲突概率
      SELECT COUNT(*)
        INTO v_cnt
      FROM bed_assignment ba
      WHERE ba.bed_id = v_bed_id
        AND COALESCE(ba.end_at, '9999-12-31 23:59:59.999') > v_now
      FOR UPDATE;

      IF v_cnt = 0 THEN
        INSERT INTO bed_assignment (
          admission_id,
          bed_id,
          start_at,
          end_at,
          note
        )
        VALUES (
          o_admission_id,
          v_bed_id,
          v_now,
          NULL,
          p_note
        );

        SET o_bed_assignment_id = LAST_INSERT_ID();
        SET o_assigned_bed_id = v_bed_id;
        LEAVE bed_loop;
      END IF;
    END LOOP;
    CLOSE cur_candidate_beds;

    IF o_bed_assignment_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'no available bed found';
    END IF;
  END IF;

  COMMIT;
END$$

-- 功能：为指定入院记录分配/更换床位（结束当前占用并创建新的占用）。
-- 说明：适用病人转床；床位冲突由触发器 trg_bed_assignment_bi_no_overlap 与本过程的锁定共同控制。
DROP PROCEDURE IF EXISTS sp_bed_assignment_transfer$$
CREATE PROCEDURE sp_bed_assignment_transfer(
  IN p_admission_id BIGINT UNSIGNED,
  IN p_new_bed_id BIGINT UNSIGNED,
  IN p_note VARCHAR(500),
  OUT o_old_bed_assignment_id BIGINT UNSIGNED,
  OUT o_new_bed_assignment_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_now DATETIME(3);
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_admission_id IS NULL OR p_new_bed_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'admission_id and new_bed_id are required';
  END IF;

  SET v_now = CURRENT_TIMESTAMP(3);

  START TRANSACTION;

  SELECT COUNT(*)
    INTO v_cnt
  FROM admission a
  WHERE a.admission_id = p_admission_id
    AND a.status = 'ADMITTED'
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'admission not found or not ADMITTED';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM bed b
  WHERE b.bed_id = p_new_bed_id
    AND b.status = 'AVAILABLE'
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'new bed not found or not AVAILABLE';
  END IF;

  SELECT ba.bed_assignment_id
    INTO o_old_bed_assignment_id
  FROM bed_assignment ba
  WHERE ba.admission_id = p_admission_id
    AND ba.end_at IS NULL
  ORDER BY ba.start_at DESC
  LIMIT 1
  FOR UPDATE;

  IF o_old_bed_assignment_id IS NOT NULL THEN
    UPDATE bed_assignment ba
    SET
      ba.end_at = v_now,
      ba.note = COALESCE(p_note, ba.note)
    WHERE ba.bed_assignment_id = o_old_bed_assignment_id;
  END IF;

  INSERT INTO bed_assignment (
    admission_id,
    bed_id,
    start_at,
    end_at,
    note
  )
  VALUES (
    p_admission_id,
    p_new_bed_id,
    v_now,
    NULL,
    p_note
  );
  SET o_new_bed_assignment_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：办理出院（结束床位占用、更新 admission 状态，并可选关闭 encounter）。
-- 说明：encounter 与 admission 未建立外键关系，本过程可选接收 encounter_id 以便一并关闭就诊记录。
DROP PROCEDURE IF EXISTS sp_inpatient_discharge$$
CREATE PROCEDURE sp_inpatient_discharge(
  IN p_admission_id BIGINT UNSIGNED,
  IN p_encounter_id BIGINT UNSIGNED,
  IN p_note VARCHAR(1000)
)
BEGIN
  DECLARE v_now DATETIME(3);
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_admission_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'admission_id is required';
  END IF;

  SET v_now = CURRENT_TIMESTAMP(3);

  START TRANSACTION;

  SELECT COUNT(*)
    INTO v_cnt
  FROM admission a
  WHERE a.admission_id = p_admission_id
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'admission not found';
  END IF;

  UPDATE bed_assignment ba
  SET
    ba.end_at = v_now,
    ba.note = COALESCE(p_note, ba.note)
  WHERE ba.admission_id = p_admission_id
    AND ba.end_at IS NULL;

  UPDATE admission a
  SET
    a.discharged_at = v_now,
    a.status = 'DISCHARGED',
    a.note = COALESCE(p_note, a.note)
  WHERE a.admission_id = p_admission_id;

  IF p_encounter_id IS NOT NULL THEN
    UPDATE encounter e
    SET
      e.ended_at = v_now,
      e.status = 'CLOSED',
      e.note = COALESCE(p_note, e.note)
    WHERE e.encounter_id = p_encounter_id;
  END IF;

  COMMIT;
END$$
