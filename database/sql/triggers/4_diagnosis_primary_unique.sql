-- =========================
-- 业务触发器：诊断主诊断唯一（同一就诊只能有一个 PRIMARY）
-- =========================

-- 功能：诊断插入前确保同一就诊仅有一个主诊断。
CREATE TRIGGER trg_diagnosis_bi_primary_unique
BEFORE INSERT ON diagnosis
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  IF NEW.diagnosis_type = 'PRIMARY' THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM diagnosis
    WHERE encounter_id = NEW.encounter_id
      AND diagnosis_type = 'PRIMARY';
    IF v_cnt > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Encounter already has a PRIMARY diagnosis';
    END IF;
  END IF;
END$$

-- 功能：诊断更新前确保同一就诊仅有一个主诊断。
CREATE TRIGGER trg_diagnosis_bu_primary_unique
BEFORE UPDATE ON diagnosis
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  IF NEW.diagnosis_type = 'PRIMARY' THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM diagnosis
    WHERE encounter_id = NEW.encounter_id
      AND diagnosis_type = 'PRIMARY'
      AND diagnosis_id <> OLD.diagnosis_id;
    IF v_cnt > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Encounter already has a PRIMARY diagnosis';
    END IF;
  END IF;
END$$

