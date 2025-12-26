-- =========================
-- 例程：门诊挂号与就诊
-- =========================

-- 功能：完成一次门诊挂号并自动创建对应就诊（encounter），同时生成挂号费费用（charge）。
-- 说明：依赖触发器 trg_registration_bi_quota_check 校验号源配额；费用金额由触发器 trg_charge_bi_calc_amount 保障。
DROP PROCEDURE IF EXISTS sp_outpatient_register$$
CREATE PROCEDURE sp_outpatient_register(
  IN p_patient_id BIGINT UNSIGNED,
  IN p_schedule_id BIGINT UNSIGNED,
  IN p_chief_complaint VARCHAR(500),
  OUT o_registration_id BIGINT UNSIGNED,
  OUT o_registration_no VARCHAR(40),
  OUT o_encounter_id BIGINT UNSIGNED,
  OUT o_encounter_no VARCHAR(40),
  OUT o_charge_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_department_id BIGINT UNSIGNED;
  DECLARE v_doctor_id BIGINT UNSIGNED;
  DECLARE v_registration_fee DECIMAL(10,2);
  DECLARE v_charge_item_id BIGINT UNSIGNED;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_patient_id IS NULL OR p_schedule_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient_id and schedule_id are required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM patient p WHERE p.patient_id = p_patient_id AND p.is_active = 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient not found or inactive';
  END IF;

  SELECT s.department_id, s.doctor_id, s.registration_fee
    INTO v_department_id, v_doctor_id, v_registration_fee
  FROM doctor_schedule s
  WHERE s.schedule_id = p_schedule_id;

  IF v_department_id IS NULL OR v_doctor_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'schedule not found';
  END IF;

  SELECT cc.charge_item_id
    INTO v_charge_item_id
  FROM charge_catalog cc
  WHERE cc.item_code = 'REG_FEE' AND cc.is_active = 1
  LIMIT 1;

  IF v_charge_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'charge_catalog REG_FEE not found or inactive';
  END IF;

  START TRANSACTION;

  SET o_registration_no = CONCAT('reg_', UUID_SHORT());
  INSERT INTO registration (
    registration_no,
    patient_id,
    schedule_id,
    status,
    chief_complaint
  )
  VALUES (
    o_registration_no,
    p_patient_id,
    p_schedule_id,
    'CONFIRMED',
    p_chief_complaint
  );
  SET o_registration_id = LAST_INSERT_ID();

  SET o_encounter_no = CONCAT('enc_', UUID_SHORT());
  INSERT INTO encounter (
    encounter_no,
    patient_id,
    department_id,
    doctor_id,
    registration_id,
    encounter_type,
    status
  )
  VALUES (
    o_encounter_no,
    p_patient_id,
    v_department_id,
    v_doctor_id,
    o_registration_id,
    'OUTPATIENT',
    'OPEN'
  );
  SET o_encounter_id = LAST_INSERT_ID();

  INSERT INTO charge (
    charge_no,
    encounter_id,
    source_type,
    source_id,
    charge_item_id,
    quantity,
    unit_price,
    status
  )
  VALUES (
    CONCAT('chg_', UUID_SHORT()),
    o_encounter_id,
    'REGISTRATION',
    o_registration_id,
    v_charge_item_id,
    1.00,
    v_registration_fee,
    'UNBILLED'
  );
  SET o_charge_id = LAST_INSERT_ID();

  COMMIT;
END$$

