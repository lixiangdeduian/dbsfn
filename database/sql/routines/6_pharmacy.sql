-- =========================
-- 例程：处方开立与发药
-- =========================

-- 功能：创建处方主单（prescription），返回 prescription_id/prescription_no。
-- 说明：处方明细需通过 sp_prescription_add_item 逐条添加；金额由触发器 trg_prescription_item_* 自动重算。
DROP PROCEDURE IF EXISTS sp_prescription_create$$
CREATE PROCEDURE sp_prescription_create(
  IN p_encounter_id BIGINT UNSIGNED,
  IN p_doctor_id BIGINT UNSIGNED,
  IN p_status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED'),
  IN p_note VARCHAR(500),
  OUT o_prescription_id BIGINT UNSIGNED,
  OUT o_prescription_no VARCHAR(40)
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

  SET o_prescription_no = CONCAT('rx_', UUID_SHORT());
  INSERT INTO prescription (
    prescription_no,
    encounter_id,
    doctor_id,
    status,
    note
  )
  VALUES (
    o_prescription_no,
    p_encounter_id,
    p_doctor_id,
    IFNULL(p_status, 'ISSUED'),
    p_note
  );

  SET o_prescription_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：向处方添加一条明细（prescription_item），返回 prescription_item_id。
-- 说明：unit_price/amount 由触发器 trg_prescription_item_bi_calc_amount 自动补齐与计算。
DROP PROCEDURE IF EXISTS sp_prescription_add_item$$
CREATE PROCEDURE sp_prescription_add_item(
  IN p_prescription_id BIGINT UNSIGNED,
  IN p_drug_id BIGINT UNSIGNED,
  IN p_quantity DECIMAL(12,2),
  IN p_usage_instructions VARCHAR(200),
  IN p_frequency VARCHAR(50),
  IN p_days INT UNSIGNED,
  OUT o_prescription_item_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED');
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_prescription_id IS NULL OR p_drug_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription_id and drug_id are required';
  END IF;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity must be > 0';
  END IF;

  START TRANSACTION;

  SELECT p.status
    INTO v_status
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription not found';
  END IF;

  IF v_status IN ('DISPENSED','CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot modify DISPENSED/CANCELLED prescription';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM drug d
  WHERE d.drug_id = p_drug_id
    AND d.is_active = 1
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'drug not found or inactive';
  END IF;

  INSERT INTO prescription_item (
    prescription_id,
    drug_id,
    quantity,
    unit_price,
    usage_instructions,
    frequency,
    days
  )
  VALUES (
    p_prescription_id,
    p_drug_id,
    p_quantity,
    NULL,
    p_usage_instructions,
    p_frequency,
    p_days
  );

  SET o_prescription_item_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：将处方总金额同步为一条费用（charge，source_type='PRESCRIPTION'），用于后续开票。
-- 说明：若费用不存在则创建，存在则更新 unit_price；收费项目使用 charge_catalog.item_code='RX_TOTAL'。
DROP PROCEDURE IF EXISTS sp_prescription_bill_sync$$
CREATE PROCEDURE sp_prescription_bill_sync(
  IN p_prescription_id BIGINT UNSIGNED,
  OUT o_charge_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_encounter_id BIGINT UNSIGNED;
  DECLARE v_total_amount DECIMAL(12,2);
  DECLARE v_status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED');
  DECLARE v_charge_item_id BIGINT UNSIGNED;
  DECLARE v_existing_charge_id BIGINT UNSIGNED;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_prescription_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription_id is required';
  END IF;

  START TRANSACTION;

  SELECT p.encounter_id, p.total_amount, p.status
    INTO v_encounter_id, v_total_amount, v_status
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_encounter_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription not found';
  END IF;

  SELECT cc.charge_item_id
    INTO v_charge_item_id
  FROM charge_catalog cc
  WHERE cc.item_code = 'RX_TOTAL' AND cc.is_active = 1
  LIMIT 1
  FOR UPDATE;

  IF v_charge_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'charge_catalog RX_TOTAL not found or inactive';
  END IF;

  SELECT c.charge_id
    INTO v_existing_charge_id
  FROM charge c
  WHERE c.source_type = 'PRESCRIPTION'
    AND c.source_id = p_prescription_id
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
      'PRESCRIPTION',
      p_prescription_id,
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

-- 功能：完成一次发药（dispense），并将处方状态置为 DISPENSED，同时同步处方费用（charge）。
-- 约束：只允许对 ISSUED 状态处方发药；处方无明细时不允许发药。
DROP PROCEDURE IF EXISTS sp_dispense_create$$
CREATE PROCEDURE sp_dispense_create(
  IN p_prescription_id BIGINT UNSIGNED,
  IN p_pharmacist_id BIGINT UNSIGNED,
  IN p_note VARCHAR(500),
  OUT o_dispense_id BIGINT UNSIGNED,
  OUT o_charge_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED');
  DECLARE v_encounter_id BIGINT UNSIGNED;
  DECLARE v_total_amount DECIMAL(12,2);
  DECLARE v_charge_item_id BIGINT UNSIGNED;
  DECLARE v_existing_charge_id BIGINT UNSIGNED;
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_prescription_id IS NULL OR p_pharmacist_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription_id and pharmacist_id are required';
  END IF;

  START TRANSACTION;

  SELECT p.status
    INTO v_status
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription not found';
  END IF;

  IF v_status <> 'ISSUED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'only ISSUED prescription can be dispensed';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM prescription_item pi
  WHERE pi.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription has no items';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM staff s
  WHERE s.staff_id = p_pharmacist_id
    AND s.is_active = 1
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'pharmacist not found or inactive';
  END IF;

  INSERT INTO dispense (
    prescription_id,
    pharmacist_id,
    status,
    note
  )
  VALUES (
    p_prescription_id,
    p_pharmacist_id,
    'DISPENSED',
    p_note
  );

  SET o_dispense_id = LAST_INSERT_ID();

  UPDATE prescription p
  SET
    p.status = 'DISPENSED',
    p.note = COALESCE(p_note, p.note)
  WHERE p.prescription_id = p_prescription_id;

  -- 同步处方费用（避免调用包含事务控制的过程造成隐式 COMMIT）
  SELECT p.encounter_id, p.total_amount
    INTO v_encounter_id, v_total_amount
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  SELECT cc.charge_item_id
    INTO v_charge_item_id
  FROM charge_catalog cc
  WHERE cc.item_code = 'RX_TOTAL' AND cc.is_active = 1
  LIMIT 1
  FOR UPDATE;

  IF v_charge_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'charge_catalog RX_TOTAL not found or inactive';
  END IF;

  SELECT c.charge_id
    INTO v_existing_charge_id
  FROM charge c
  WHERE c.source_type = 'PRESCRIPTION'
    AND c.source_id = p_prescription_id
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
      'PRESCRIPTION',
      p_prescription_id,
      v_charge_item_id,
      1.00,
      ROUND(IFNULL(v_total_amount, 0.00), 2),
      'UNBILLED'
    );
    SET o_charge_id = LAST_INSERT_ID();
  ELSE
    UPDATE charge c
    SET
      c.charge_item_id = v_charge_item_id,
      c.quantity = 1.00,
      c.unit_price = ROUND(IFNULL(v_total_amount, 0.00), 2)
    WHERE c.charge_id = v_existing_charge_id;
    SET o_charge_id = v_existing_charge_id;
  END IF;

  COMMIT;
END$$

-- 功能：完成一次发药（dispense），并将处方状态置为 DISPENSED，同时同步处方费用（charge）。
-- 与 sp_dispense_create 的区别：支持传入 dispensed_at（例如补录历史发药）。
DROP PROCEDURE IF EXISTS sp_dispense_prescription$$
CREATE PROCEDURE sp_dispense_prescription(
  IN p_prescription_id BIGINT UNSIGNED,
  IN p_pharmacist_id BIGINT UNSIGNED,
  IN p_dispensed_at DATETIME(3),
  IN p_note VARCHAR(500),
  OUT o_dispense_id BIGINT UNSIGNED,
  OUT o_charge_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED');
  DECLARE v_encounter_id BIGINT UNSIGNED;
  DECLARE v_total_amount DECIMAL(12,2);
  DECLARE v_charge_item_id BIGINT UNSIGNED;
  DECLARE v_existing_charge_id BIGINT UNSIGNED;
  DECLARE v_cnt INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_prescription_id IS NULL OR p_pharmacist_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription_id and pharmacist_id are required';
  END IF;

  START TRANSACTION;

  SELECT p.status
    INTO v_status
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription not found';
  END IF;

  IF v_status <> 'ISSUED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'only ISSUED prescription can be dispensed';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM prescription_item pi
  WHERE pi.prescription_id = p_prescription_id
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prescription has no items';
  END IF;

  SELECT COUNT(*)
    INTO v_cnt
  FROM staff s
  WHERE s.staff_id = p_pharmacist_id
    AND s.is_active = 1
  FOR UPDATE;

  IF v_cnt = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'pharmacist not found or inactive';
  END IF;

  INSERT INTO dispense (
    prescription_id,
    pharmacist_id,
    dispensed_at,
    status,
    note
  )
  VALUES (
    p_prescription_id,
    p_pharmacist_id,
    COALESCE(p_dispensed_at, CURRENT_TIMESTAMP(3)),
    'DISPENSED',
    p_note
  );

  SET o_dispense_id = LAST_INSERT_ID();

  UPDATE prescription p
  SET
    p.status = 'DISPENSED',
    p.note = COALESCE(p_note, p.note)
  WHERE p.prescription_id = p_prescription_id;

  -- 同步处方费用（避免调用包含事务控制的过程造成隐式 COMMIT）
  SELECT p.encounter_id, p.total_amount
    INTO v_encounter_id, v_total_amount
  FROM prescription p
  WHERE p.prescription_id = p_prescription_id
  FOR UPDATE;

  SELECT cc.charge_item_id
    INTO v_charge_item_id
  FROM charge_catalog cc
  WHERE cc.item_code = 'RX_TOTAL' AND cc.is_active = 1
  LIMIT 1
  FOR UPDATE;

  IF v_charge_item_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'charge_catalog RX_TOTAL not found or inactive';
  END IF;

  SELECT c.charge_id
    INTO v_existing_charge_id
  FROM charge c
  WHERE c.source_type = 'PRESCRIPTION'
    AND c.source_id = p_prescription_id
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
      'PRESCRIPTION',
      p_prescription_id,
      v_charge_item_id,
      1.00,
      ROUND(IFNULL(v_total_amount, 0.00), 2),
      'UNBILLED'
    );
    SET o_charge_id = LAST_INSERT_ID();
  ELSE
    UPDATE charge c
    SET
      c.charge_item_id = v_charge_item_id,
      c.quantity = 1.00,
      c.unit_price = ROUND(IFNULL(v_total_amount, 0.00), 2)
    WHERE c.charge_id = v_existing_charge_id;
    SET o_charge_id = v_existing_charge_id;
  END IF;

  COMMIT;
END$$
