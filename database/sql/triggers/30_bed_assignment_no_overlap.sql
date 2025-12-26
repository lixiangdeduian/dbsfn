-- =========================
-- 业务触发器：床位分配时间段冲突校验
-- =========================

-- 功能：床位分配插入前校验同一床位时间段不重叠。
CREATE TRIGGER trg_bed_assignment_bi_no_overlap
BEFORE INSERT ON bed_assignment
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  DECLARE v_new_end DATETIME(3);

  SET v_new_end = COALESCE(NEW.end_at, '9999-12-31 23:59:59.999');

  SELECT COUNT(*)
    INTO v_cnt
  FROM bed_assignment ba
  WHERE ba.bed_id = NEW.bed_id
    AND COALESCE(ba.end_at, '9999-12-31 23:59:59.999') > NEW.start_at
    AND v_new_end > ba.start_at;

  IF v_cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is already assigned in the given time range';
  END IF;
END$$

-- 功能：床位分配更新前校验同一床位时间段不重叠。
CREATE TRIGGER trg_bed_assignment_bu_no_overlap
BEFORE UPDATE ON bed_assignment
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  DECLARE v_new_end DATETIME(3);

  SET v_new_end = COALESCE(NEW.end_at, '9999-12-31 23:59:59.999');

  SELECT COUNT(*)
    INTO v_cnt
  FROM bed_assignment ba
  WHERE ba.bed_id = NEW.bed_id
    AND ba.bed_assignment_id <> OLD.bed_assignment_id
    AND COALESCE(ba.end_at, '9999-12-31 23:59:59.999') > NEW.start_at
    AND v_new_end > ba.start_at;

  IF v_cnt > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is already assigned in the given time range';
  END IF;
END$$

