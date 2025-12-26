-- =========================
-- 例程：检验开单与出结果（包含游标示例）
-- =========================

-- 功能：创建检验主单（lab_order），返回 lab_order_id/lab_order_no。
-- 说明：检验明细需通过 sp_lab_order_add_item 逐条添加；金额由触发器 trg_lab_order_item_* 自动重算。
DROP PROCEDURE IF EXISTS sp_lab_order_create$$
CREATE PROCEDURE sp_lab_order_create(
  IN p_encounter_id BIGINT UNSIGNED,
  IN p_doctor_id BIGINT UNSIGNED,
  IN p_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED'),
  IN p_note VARCHAR(500),
  OUT o_lab_order_id BIGINT UNSIGNED,
  OUT o_lab_order_no VARCHAR(40)
)
BEGIN
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_encounter_id IS NULL OR p_doctor_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'encounter_id and doctor_id are required';
  END IF;

  START TRANSACTION;

  SELECT COUNT(*)
    INTO v_cnt
  FROM encounter e
  WHERE e.encounter_id = p_encounter_id
    AND e.status <> 'CANCELLED'
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'encounter not found or cancelled';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM staff s
  WHERE s.staff_id = p_doctor_id
    AND s.is_active = 1
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'doctor not found or inactive';
  END IF;

  SET o_lab_order_no = CONCAT('lab_', UUID_SHORT());
  INSERT INTO lab_order (
    lab_order_no,
    encounter_id,
    doctor_id,
    status,
    note
  )
  VALUES (
    o_lab_order_no,
    p_encounter_id,
    p_doctor_id,
    IFNULL(p_status, 'ORDERED'),
    p_note
  );

  SET o_lab_order_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：向检验单添加一条明细（lab_order_item），返回 lab_order_item_id。
-- 说明：unit_price/amount 由触发器 trg_lab_order_item_bi_calc_amount 自动补齐与计算。
DROP PROCEDURE IF EXISTS sp_lab_order_add_item$$
CREATE PROCEDURE sp_lab_order_add_item(
  IN p_lab_order_id BIGINT UNSIGNED,
  IN p_lab_test_id BIGINT UNSIGNED,
  IN p_quantity INT UNSIGNED,
  OUT o_lab_order_item_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_id IS NULL OR p_lab_test_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_id and lab_test_id are required';
  END IF;

  IF p_quantity IS NULL OR p_quantity < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity must be >= 1';
  END IF;

  START TRANSACTION;

  SELECT lo.status
    INTO v_status
  FROM lab_order lo
  WHERE lo.lab_order_id = p_lab_order_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order not found';
  END IF;

  IF v_status IN ('REPORTED','CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot modify REPORTED/CANCELLED lab_order';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM lab_test lt
  WHERE lt.lab_test_id = p_lab_test_id
    AND lt.is_active = 1
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_test not found or inactive';
  END IF;

  INSERT INTO lab_order_item (
    lab_order_id,
    lab_test_id,
    quantity,
    unit_price
  )
  VALUES (
    p_lab_order_id,
    p_lab_test_id,
    IFNULL(p_quantity, 1),
    NULL
  );

  SET o_lab_order_item_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：标记检验单已采样（ORDERED -> COLLECTED）。
-- 说明：适用采样完成后调用；若已是 COLLECTED/REPORTED/CANCELLED 则不修改。
DROP PROCEDURE IF EXISTS sp_lab_order_mark_collected$$
CREATE PROCEDURE sp_lab_order_mark_collected(
  IN p_lab_order_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_id is required';
  END IF;

  START TRANSACTION;

  SELECT lo.status
    INTO v_status
  FROM lab_order lo
  WHERE lo.lab_order_id = p_lab_order_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order not found';
  END IF;

  IF v_status = 'ORDERED' THEN
    UPDATE lab_order lo
    SET lo.status = 'COLLECTED'
    WHERE lo.lab_order_id = p_lab_order_id;
  END IF;

  COMMIT;
END$$

-- 功能：将检验单总金额同步为一条费用（charge，source_type='LAB'），用于后续开票。
-- 说明：若费用不存在则创建，存在则更新 unit_price；收费项目使用 charge_catalog.item_code='LAB_TOTAL'。
DROP PROCEDURE IF EXISTS sp_lab_order_bill_sync$$
CREATE PROCEDURE sp_lab_order_bill_sync(
  IN p_lab_order_id BIGINT UNSIGNED,
  OUT o_charge_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_encounter_id BIGINT UNSIGNED;
  DECLARE v_total_amount DECIMAL(12,2);
  DECLARE v_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');
  DECLARE v_charge_item_id BIGINT UNSIGNED;
  DECLARE v_existing_charge_id BIGINT UNSIGNED;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_id is required';
  END IF;

  START TRANSACTION;

  SELECT lo.encounter_id, lo.total_amount, lo.status
    INTO v_encounter_id, v_total_amount, v_status
  FROM lab_order lo
  WHERE lo.lab_order_id = p_lab_order_id
  FOR UPDATE;

  IF v_encounter_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order not found';
  END IF;

  SELECT cc.charge_item_id
    INTO v_charge_item_id
  FROM charge_catalog cc
  WHERE cc.item_code = 'LAB_TOTAL' AND cc.is_active = 1
  LIMIT 1
  FOR UPDATE;

  IF v_charge_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'charge_catalog LAB_TOTAL not found or inactive';
  END IF;

  SELECT c.charge_id
    INTO v_existing_charge_id
  FROM charge c
  WHERE c.source_type = 'LAB'
    AND c.source_id = p_lab_order_id
    AND c.encounter_id = v_encounter_id
  LIMIT 1
  FOR UPDATE;

  IF v_existing_charge_id IS NULL THEN
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
      v_encounter_id,
      'LAB',
      p_lab_order_id,
      v_charge_item_id,
      1.00,
      ROUND(IFNULL(v_total_amount, 0.00), 2),
      CASE WHEN v_status = 'CANCELLED' THEN 'CANCELLED' ELSE 'UNBILLED' END
    );
    SET o_charge_id = LAST_INSERT_ID();
  ELSE
    UPDATE charge c
    SET
      c.charge_item_id = v_charge_item_id,
      c.quantity = 1.00,
      c.unit_price = ROUND(IFNULL(v_total_amount, 0.00), 2),
      c.status = CASE WHEN v_status = 'CANCELLED' THEN 'CANCELLED' ELSE c.status END
    WHERE c.charge_id = v_existing_charge_id;
    SET o_charge_id = v_existing_charge_id;
  END IF;

  COMMIT;
END$$

-- 功能：为检验单的每条明细创建结果占位（lab_result），便于检验端逐项录入结果。
-- 说明：内部使用游标逐条处理 lab_order_item；若结果已存在则跳过；可选同时更新 lab_order 状态为 COLLECTED。
DROP PROCEDURE IF EXISTS sp_lab_order_prepare_results$$
CREATE PROCEDURE sp_lab_order_prepare_results(
  IN p_lab_order_id BIGINT UNSIGNED,
  IN p_technician_id BIGINT UNSIGNED,
  IN p_mark_collected TINYINT(1),
  OUT o_created_count INT
)
BEGIN
  DECLARE v_item_id BIGINT UNSIGNED;
  DECLARE v_done TINYINT(1) DEFAULT 0;
  DECLARE v_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');
  DECLARE v_cnt INT DEFAULT 0;

  -- 游标：遍历检验单明细
  DECLARE cur_items CURSOR FOR
    SELECT loi.lab_order_item_id
    FROM lab_order_item loi
    WHERE loi.lab_order_id = p_lab_order_id
    ORDER BY loi.lab_order_item_id
    FOR UPDATE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_id is required';
  END IF;

  START TRANSACTION;

  SELECT lo.status
    INTO v_status
  FROM lab_order lo
  WHERE lo.lab_order_id = p_lab_order_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order not found';
  END IF;

  IF v_status IN ('REPORTED','CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot prepare results for REPORTED/CANCELLED lab_order';
  END IF;

  IF p_technician_id IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM staff s
    WHERE s.staff_id = p_technician_id
      AND s.is_active = 1
    FOR UPDATE;

    IF v_cnt = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'technician not found or inactive';
    END IF;
  END IF;

  SET o_created_count = 0;

  OPEN cur_items;
  item_loop: LOOP
    FETCH cur_items INTO v_item_id;
    IF v_done = 1 THEN
      LEAVE item_loop;
    END IF;

    INSERT IGNORE INTO lab_result (
      lab_order_item_id,
      result_flag,
      technician_id
    )
    VALUES (
      v_item_id,
      'UNKNOWN',
      p_technician_id
    );

    IF ROW_COUNT() > 0 THEN
      SET o_created_count = o_created_count + 1;
    END IF;
  END LOOP;
  CLOSE cur_items;

  IF p_mark_collected = 1 AND v_status = 'ORDERED' THEN
    UPDATE lab_order lo
    SET lo.status = 'COLLECTED'
    WHERE lo.lab_order_id = p_lab_order_id;
  END IF;

  COMMIT;
END$$

-- 功能：录入或更新某条检验明细的结果（lab_result），并在全部明细均已有结果后自动将检验单置为 REPORTED。
-- 说明：result_at 为空时默认取当前时间；若检验单为 CANCELLED 则拒绝写入。
DROP PROCEDURE IF EXISTS sp_lab_result_upsert$$
CREATE PROCEDURE sp_lab_result_upsert(
  IN p_lab_order_item_id BIGINT UNSIGNED,
  IN p_technician_id BIGINT UNSIGNED,
  IN p_result_value VARCHAR(200),
  IN p_result_text VARCHAR(1000),
  IN p_result_flag ENUM('NORMAL','HIGH','LOW','POSITIVE','NEGATIVE','ABNORMAL','UNKNOWN'),
  IN p_result_at DATETIME(3),
  OUT o_lab_result_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_order_id BIGINT UNSIGNED;
  DECLARE v_order_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');
  DECLARE v_now DATETIME(3);
  DECLARE v_total_items INT DEFAULT 0;
  DECLARE v_done_items INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_item_id is required';
  END IF;

  SET v_now = CURRENT_TIMESTAMP(3);

  START TRANSACTION;

  SELECT loi.lab_order_id
    INTO v_order_id
  FROM lab_order_item loi
  WHERE loi.lab_order_item_id = p_lab_order_item_id
  FOR UPDATE;

  IF v_order_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_item not found';
  END IF;

  SELECT lo.status
    INTO v_order_status
  FROM lab_order lo
  WHERE lo.lab_order_id = v_order_id
  FOR UPDATE;

  IF v_order_status = 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot write result to CANCELLED lab_order';
  END IF;

  IF p_technician_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM staff s WHERE s.staff_id = p_technician_id AND s.is_active = 1) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'technician not found or inactive';
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM lab_result lr WHERE lr.lab_order_item_id = p_lab_order_item_id) THEN
    UPDATE lab_result lr
    SET
      lr.result_value = p_result_value,
      lr.result_text = p_result_text,
      lr.result_flag = IFNULL(p_result_flag, lr.result_flag),
      lr.result_at = COALESCE(p_result_at, v_now),
      lr.technician_id = COALESCE(p_technician_id, lr.technician_id)
    WHERE lr.lab_order_item_id = p_lab_order_item_id;

    SELECT lr.lab_result_id
      INTO o_lab_result_id
    FROM lab_result lr
    WHERE lr.lab_order_item_id = p_lab_order_item_id
    FOR UPDATE;
  ELSE
    INSERT INTO lab_result (
      lab_order_item_id,
      result_value,
      result_text,
      result_flag,
      result_at,
      technician_id
    )
    VALUES (
      p_lab_order_item_id,
      p_result_value,
      p_result_text,
      IFNULL(p_result_flag, 'UNKNOWN'),
      COALESCE(p_result_at, v_now),
      p_technician_id
    );
    SET o_lab_result_id = LAST_INSERT_ID();
  END IF;

  SELECT COUNT(*)
    INTO v_total_items
  FROM lab_order_item loi
  WHERE loi.lab_order_id = v_order_id
  FOR UPDATE;

  SELECT COUNT(*)
    INTO v_done_items
  FROM lab_order_item loi
  JOIN lab_result lr ON lr.lab_order_item_id = loi.lab_order_item_id
  WHERE loi.lab_order_id = v_order_id
    AND lr.result_at IS NOT NULL
  FOR UPDATE;

  IF v_total_items > 0 AND v_done_items = v_total_items AND v_order_status <> 'CANCELLED' THEN
    UPDATE lab_order lo
    SET lo.status = 'REPORTED'
    WHERE lo.lab_order_id = v_order_id
      AND lo.status <> 'CANCELLED';
  END IF;

  COMMIT;
END$$

-- 功能：审核某条检验结果（设置 verified_by/verified_at），并在全部明细均已审核后将检验单置为 REPORTED。
-- 说明：适用检验结果复核流程；若结果记录不存在则报错。
DROP PROCEDURE IF EXISTS sp_lab_result_verify$$
CREATE PROCEDURE sp_lab_result_verify(
  IN p_lab_order_item_id BIGINT UNSIGNED,
  IN p_verified_by BIGINT UNSIGNED
)
BEGIN
  DECLARE v_order_id BIGINT UNSIGNED;
  DECLARE v_order_status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED');
  DECLARE v_now DATETIME(3);
  DECLARE v_total_items INT DEFAULT 0;
  DECLARE v_verified_items INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_lab_order_item_id IS NULL OR p_verified_by IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_item_id and verified_by are required';
  END IF;

  SET v_now = CURRENT_TIMESTAMP(3);

  START TRANSACTION;

  SELECT loi.lab_order_id
    INTO v_order_id
  FROM lab_order_item loi
  WHERE loi.lab_order_item_id = p_lab_order_item_id
  FOR UPDATE;

  IF v_order_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_order_item not found';
  END IF;

  SELECT lo.status
    INTO v_order_status
  FROM lab_order lo
  WHERE lo.lab_order_id = v_order_id
  FOR UPDATE;

  IF v_order_status = 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot verify result for CANCELLED lab_order';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM staff s WHERE s.staff_id = p_verified_by AND s.is_active = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'verified_by not found or inactive';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM lab_result lr WHERE lr.lab_order_item_id = p_lab_order_item_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_result not found for lab_order_item';
  END IF;

  UPDATE lab_result lr
  SET
    lr.verified_by = p_verified_by,
    lr.verified_at = v_now
  WHERE lr.lab_order_item_id = p_lab_order_item_id;

  SELECT COUNT(*)
    INTO v_total_items
  FROM lab_order_item loi
  WHERE loi.lab_order_id = v_order_id
  FOR UPDATE;

  SELECT COUNT(*)
    INTO v_verified_items
  FROM lab_order_item loi
  JOIN lab_result lr ON lr.lab_order_item_id = loi.lab_order_item_id
  WHERE loi.lab_order_id = v_order_id
    AND lr.verified_at IS NOT NULL
  FOR UPDATE;

  IF v_total_items > 0 AND v_verified_items = v_total_items THEN
    UPDATE lab_order lo
    SET lo.status = 'REPORTED'
    WHERE lo.lab_order_id = v_order_id
      AND lo.status <> 'CANCELLED';
  END IF;

  COMMIT;
END$$
