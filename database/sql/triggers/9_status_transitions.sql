-- =========================
-- 业务触发器：状态联动与关键一致性校验
-- =========================

-- 功能：就诊关闭/取消时自动补齐 ended_at。
CREATE TRIGGER trg_encounter_bu_set_end_time
BEFORE UPDATE ON encounter
FOR EACH ROW
BEGIN
  IF NEW.status IN ('CLOSED','CANCELLED') AND NEW.ended_at IS NULL THEN
    SET NEW.ended_at = CURRENT_TIMESTAMP(3);
  END IF;
END$$

-- 功能：就诊状态变化时联动挂号状态（门诊）。
CREATE TRIGGER trg_encounter_au_sync_registration_status
AFTER UPDATE ON encounter
FOR EACH ROW
BEGIN
  IF NEW.registration_id IS NOT NULL AND OLD.status <> NEW.status THEN
    IF NEW.status = 'CLOSED' THEN
      UPDATE registration r
      SET r.status = 'COMPLETED'
      WHERE r.registration_id = NEW.registration_id
        AND r.status <> 'CANCELLED';
    ELSEIF NEW.status = 'CANCELLED' THEN
      UPDATE registration r
      SET r.status = 'CANCELLED'
      WHERE r.registration_id = NEW.registration_id
        AND r.status = 'CONFIRMED';
    END IF;
  END IF;
END$$

-- 功能：挂号取消前校验（已生成就诊则不允许取消）。
CREATE TRIGGER trg_registration_bu_cancel_guard
BEFORE UPDATE ON registration
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status AND NEW.status = 'CANCELLED' THEN
    IF EXISTS (
      SELECT 1 FROM encounter e
      WHERE e.registration_id = OLD.registration_id
        AND e.status <> 'CANCELLED'
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registration already used by an encounter';
    END IF;
  END IF;
END$$

-- 功能：入院插入前校验（同一患者同一时刻只允许一个在院 ADMITTED）。
CREATE TRIGGER trg_admission_bi_one_active_per_patient
BEFORE INSERT ON admission
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM admission a
    WHERE a.patient_id = NEW.patient_id AND a.status = 'ADMITTED'
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient already has an active admission';
  END IF;
END$$

-- 功能：入院更新时补齐出院时间并关闭占床记录。
CREATE TRIGGER trg_admission_bu_discharge_close_bed
BEFORE UPDATE ON admission
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status AND NEW.status = 'DISCHARGED' AND NEW.discharged_at IS NULL THEN
    SET NEW.discharged_at = CURRENT_TIMESTAMP(3);
  END IF;
END$$

CREATE TRIGGER trg_admission_au_discharge_close_bed
AFTER UPDATE ON admission
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status AND NEW.status IN ('DISCHARGED','CANCELLED') THEN
    UPDATE bed_assignment ba
    SET ba.end_at = COALESCE(NEW.discharged_at, CURRENT_TIMESTAMP(3))
    WHERE ba.admission_id = NEW.admission_id
      AND ba.end_at IS NULL;
  END IF;
END$$

-- 功能：床位分配写入前校验床位可用且入院状态为 ADMITTED。
CREATE TRIGGER trg_bed_assignment_bi_validate_bed
BEFORE INSERT ON bed_assignment
FOR EACH ROW
BEGIN
  DECLARE v_bed_status VARCHAR(20);
  DECLARE v_admission_status VARCHAR(20);

  SELECT b.status INTO v_bed_status FROM bed b WHERE b.bed_id = NEW.bed_id;
  -- 仅对“当前占用”（end_at 为 NULL）要求床位必须可用；历史占用记录允许写入。
  IF NEW.end_at IS NULL AND v_bed_status <> 'AVAILABLE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is not available';
  END IF;

  SELECT a.status INTO v_admission_status FROM admission a WHERE a.admission_id = NEW.admission_id;
  IF v_admission_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission not found';
  END IF;
  IF v_admission_status = 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission is cancelled';
  END IF;
  -- 出院记录允许写入“历史床位分配”，但必须提供 end_at。
  IF v_admission_status = 'DISCHARGED' AND NEW.end_at IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Discharged admission requires bed_assignment.end_at';
  END IF;
  -- 在院记录如果写入当前占用，end_at 必须为 NULL（避免把“在院”写成历史记录）。
  IF v_admission_status = 'ADMITTED' AND NEW.end_at IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active admission bed_assignment.end_at must be NULL';
  END IF;
END$$

CREATE TRIGGER trg_bed_assignment_bu_validate_bed
BEFORE UPDATE ON bed_assignment
FOR EACH ROW
BEGIN
  DECLARE v_bed_status VARCHAR(20);
  DECLARE v_admission_status VARCHAR(20);

  SELECT b.status INTO v_bed_status FROM bed b WHERE b.bed_id = NEW.bed_id;
  IF NEW.end_at IS NULL AND v_bed_status <> 'AVAILABLE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is not available';
  END IF;

  SELECT a.status INTO v_admission_status FROM admission a WHERE a.admission_id = NEW.admission_id;
  IF v_admission_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission not found';
  END IF;
  IF v_admission_status = 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission is cancelled';
  END IF;
  IF v_admission_status = 'DISCHARGED' AND NEW.end_at IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Discharged admission requires bed_assignment.end_at';
  END IF;
  IF v_admission_status = 'ADMITTED' AND NEW.end_at IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active admission bed_assignment.end_at must be NULL';
  END IF;
END$$

-- 功能：发药插入前校验处方状态并要求至少存在 1 条处方明细。
CREATE TRIGGER trg_dispense_bi_validate_prescription
BEFORE INSERT ON dispense
FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(20);
  DECLARE v_items INT;

  SELECT pr.status INTO v_status FROM prescription pr WHERE pr.prescription_id = NEW.prescription_id;
  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Prescription not found';
  END IF;
  -- 允许：
  -- - ISSUED：正常发药后转为 DISPENSED
  -- - DISPENSED：用于补录/重放发药记录（例如种子数据），唯一约束会防止重复插入
  IF v_status NOT IN ('ISSUED','DISPENSED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Prescription status does not allow dispensing';
  END IF;

  SELECT COUNT(*) INTO v_items FROM prescription_item pi WHERE pi.prescription_id = NEW.prescription_id;
  IF v_items <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Prescription has no items';
  END IF;

  IF NEW.status NOT IN ('DISPENSED','CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid dispense status';
  END IF;
END$$
