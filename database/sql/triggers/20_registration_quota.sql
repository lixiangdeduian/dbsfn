-- =========================
-- 业务触发器：号源配额校验
-- =========================

-- 功能：挂号插入前校验排班启用且未超出号源配额。
CREATE TRIGGER trg_registration_bi_quota_check
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
  DECLARE v_quota INT UNSIGNED;
  DECLARE v_used INT UNSIGNED;
  DECLARE v_active TINYINT(1);

  SELECT quota, is_active
    INTO v_quota, v_active
  FROM doctor_schedule
  WHERE schedule_id = NEW.schedule_id;

  IF v_active = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Schedule is inactive';
  END IF;

  SELECT COUNT(*)
    INTO v_used
  FROM registration
  WHERE schedule_id = NEW.schedule_id
    AND status IN ('CONFIRMED','COMPLETED');

  IF v_used >= v_quota THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Schedule quota exceeded';
  END IF;
END$$

