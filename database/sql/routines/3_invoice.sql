-- =========================
-- 例程：开票与作废（包含游标示例）
-- =========================

-- 功能：为一次就诊（encounter）把所有未开票费用（charge.status='UNBILLED'）集中生成一张发票并挂载明细（invoice_line）。
-- 说明：内部使用游标逐条挂载费用；由触发器 trg_invoice_line_ai_recalc 自动更新发票总额与费用状态。
DROP PROCEDURE IF EXISTS sp_invoice_create_for_encounter$$
CREATE PROCEDURE sp_invoice_create_for_encounter(
  IN p_encounter_id BIGINT UNSIGNED,
  IN p_note VARCHAR(500),
  OUT o_invoice_id BIGINT UNSIGNED,
  OUT o_invoice_no VARCHAR(40),
  OUT o_line_count INT
)
BEGIN
  DECLARE v_patient_id BIGINT UNSIGNED;
  DECLARE v_charge_id BIGINT UNSIGNED;
  DECLARE v_done TINYINT(1) DEFAULT 0;

  DECLARE cur_unbilled_charges CURSOR FOR
    SELECT c.charge_id
    FROM charge c
    WHERE c.encounter_id = p_encounter_id
      AND c.status = 'UNBILLED'
      AND c.amount > 0
    ORDER BY c.charged_at, c.charge_id
    FOR UPDATE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_encounter_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'encounter_id is required';
  END IF;

  START TRANSACTION;

  SELECT e.patient_id
    INTO v_patient_id
  FROM encounter e
  WHERE e.encounter_id = p_encounter_id;

  IF v_patient_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'encounter not found';
  END IF;

  SET o_invoice_no = CONCAT('inv_', UUID_SHORT());
  INSERT INTO invoice (
    invoice_no,
    patient_id,
    encounter_id,
    status,
    note
  )
  VALUES (
    o_invoice_no,
    v_patient_id,
    p_encounter_id,
    'OPEN',
    p_note
  );
  SET o_invoice_id = LAST_INSERT_ID();

  SET o_line_count = 0;

  -- 游标：逐条读取未开票费用并写入 invoice_line
  OPEN cur_unbilled_charges;
  read_loop: LOOP
    FETCH cur_unbilled_charges INTO v_charge_id;
    IF v_done = 1 THEN
      LEAVE read_loop;
    END IF;

    INSERT INTO invoice_line (invoice_id, charge_id)
    VALUES (o_invoice_id, v_charge_id);

    SET o_line_count = o_line_count + 1;
  END LOOP;
  CLOSE cur_unbilled_charges;

  IF o_line_count = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'no unbilled charges for encounter';
  END IF;

  COMMIT;
END$$

-- 功能：给已存在的发票追加“尚未开票”的费用（仅支持 invoice.encounter_id 非空的发票）。
-- 说明：内部使用游标遍历并追加；适用“补录费用后，发票追加明细”的后端接口。
DROP PROCEDURE IF EXISTS sp_invoice_attach_unbilled_charges$$
CREATE PROCEDURE sp_invoice_attach_unbilled_charges(
  IN p_invoice_id BIGINT UNSIGNED,
  OUT o_added_count INT
)
BEGIN
  DECLARE v_encounter_id BIGINT UNSIGNED;
  DECLARE v_invoice_status ENUM('OPEN','PARTIALLY_PAID','PAID','VOID');
  DECLARE v_charge_id BIGINT UNSIGNED;
  DECLARE v_done TINYINT(1) DEFAULT 0;

  DECLARE cur_new_charges CURSOR FOR
    SELECT c.charge_id
    FROM charge c
    WHERE c.encounter_id = v_encounter_id
      AND c.status = 'UNBILLED'
      AND c.amount > 0
      AND NOT EXISTS (
        SELECT 1 FROM invoice_line il
        WHERE il.invoice_id = p_invoice_id AND il.charge_id = c.charge_id
      )
    ORDER BY c.charged_at, c.charge_id
    FOR UPDATE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_invoice_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice_id is required';
  END IF;

  START TRANSACTION;

  SELECT i.encounter_id, i.status
    INTO v_encounter_id, v_invoice_status
  FROM invoice i
  WHERE i.invoice_id = p_invoice_id
  FOR UPDATE;

  IF v_invoice_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice not found';
  END IF;

  IF v_invoice_status = 'VOID' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot attach charges to VOID invoice';
  END IF;

  IF v_encounter_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice.encounter_id is NULL; cannot attach charges';
  END IF;

  SET o_added_count = 0;
  OPEN cur_new_charges;
  read_loop: LOOP
    FETCH cur_new_charges INTO v_charge_id;
    IF v_done = 1 THEN
      LEAVE read_loop;
    END IF;

    INSERT INTO invoice_line (invoice_id, charge_id)
    VALUES (p_invoice_id, v_charge_id);

    SET o_added_count = o_added_count + 1;
  END LOOP;
  CLOSE cur_new_charges;

  COMMIT;
END$$

-- 功能：作废发票并释放其费用（将发票明细逐条删除，使费用回到 UNBILLED，可重新开票）。
-- 约束：已发生成功支付（invoice.paid_amount > 0）的发票不允许直接作废，避免财务不一致。
DROP PROCEDURE IF EXISTS sp_invoice_void$$
CREATE PROCEDURE sp_invoice_void(
  IN p_invoice_id BIGINT UNSIGNED,
  IN p_reason VARCHAR(300),
  OUT o_detached_count INT
)
BEGIN
  DECLARE v_status ENUM('OPEN','PARTIALLY_PAID','PAID','VOID');
  DECLARE v_paid_amount DECIMAL(12,2);
  DECLARE v_line_id BIGINT UNSIGNED;
  DECLARE v_done TINYINT(1) DEFAULT 0;

  DECLARE cur_invoice_lines CURSOR FOR
    SELECT il.invoice_line_id
    FROM invoice_line il
    WHERE il.invoice_id = p_invoice_id
    ORDER BY il.invoice_line_id
    FOR UPDATE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_invoice_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice_id is required';
  END IF;

  START TRANSACTION;

  SELECT i.status, i.paid_amount
    INTO v_status, v_paid_amount
  FROM invoice i
  WHERE i.invoice_id = p_invoice_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice not found';
  END IF;

  IF v_status = 'VOID' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice already VOID';
  END IF;

  IF IFNULL(v_paid_amount, 0.00) > 0.00 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot void invoice with paid_amount > 0';
  END IF;

  SET o_detached_count = 0;
  OPEN cur_invoice_lines;
  read_loop: LOOP
    FETCH cur_invoice_lines INTO v_line_id;
    IF v_done = 1 THEN
      LEAVE read_loop;
    END IF;

    -- 游标：逐条删除发票明细，触发器会回退费用状态并更新发票总额
    DELETE FROM invoice_line WHERE invoice_line_id = v_line_id;
    SET o_detached_count = o_detached_count + 1;
  END LOOP;
  CLOSE cur_invoice_lines;

  UPDATE invoice i
  SET
    i.status = 'VOID',
    i.note = LEFT(
      CONCAT(
        IFNULL(i.note, ''),
        CASE WHEN i.note IS NULL OR i.note = '' THEN '' ELSE ' | ' END,
        'VOID: ',
        IFNULL(p_reason, '')
      ),
      500
    )
  WHERE i.invoice_id = p_invoice_id;

  COMMIT;
END$$
