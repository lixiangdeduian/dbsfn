-- =========================
-- 例程：支付与退款
-- =========================

-- 功能：创建一笔支付（payment），并由触发器联动更新发票已付金额与状态。
-- 约束：不允许对 VOID 发票支付；不允许支付金额超过剩余应付金额（total_amount - paid_amount）。
DROP PROCEDURE IF EXISTS sp_payment_create$$
CREATE PROCEDURE sp_payment_create(
  IN p_invoice_id BIGINT UNSIGNED,
  IN p_method ENUM('CASH','CARD','WECHAT','ALIPAY','TRANSFER','OTHER'),
  IN p_amount DECIMAL(12,2),
  IN p_transaction_ref VARCHAR(100),
  OUT o_payment_id BIGINT UNSIGNED,
  OUT o_payment_no VARCHAR(40)
)
BEGIN
  DECLARE v_status ENUM('OPEN','PARTIALLY_PAID','PAID','VOID');
  DECLARE v_total_amount DECIMAL(12,2);
  DECLARE v_paid_amount DECIMAL(12,2);
  DECLARE v_remaining DECIMAL(12,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_invoice_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice_id is required';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'amount must be > 0';
  END IF;

  START TRANSACTION;

  SELECT i.status, i.total_amount, i.paid_amount
    INTO v_status, v_total_amount, v_paid_amount
  FROM invoice i
  WHERE i.invoice_id = p_invoice_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice not found';
  END IF;

  IF v_status = 'VOID' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cannot pay VOID invoice';
  END IF;

  SET v_remaining = ROUND(IFNULL(v_total_amount, 0.00) - IFNULL(v_paid_amount, 0.00), 2);

  IF p_amount > v_remaining THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment amount exceeds remaining amount';
  END IF;

  SET o_payment_no = CONCAT('pay_', UUID_SHORT());
  INSERT INTO payment (
    payment_no,
    invoice_id,
    method,
    amount,
    status,
    transaction_ref
  )
  VALUES (
    o_payment_no,
    p_invoice_id,
    IFNULL(p_method, 'CASH'),
    p_amount,
    'SUCCESS',
    p_transaction_ref
  );

  SET o_payment_id = LAST_INSERT_ID();

  COMMIT;
END$$

-- 功能：创建一笔退款（refund），并由触发器联动更新发票已付金额与状态。
-- 约束：退款金额不能超过该支付记录的可退余额（payment.amount - 已成功退款合计）。
DROP PROCEDURE IF EXISTS sp_refund_create$$
CREATE PROCEDURE sp_refund_create(
  IN p_payment_id BIGINT UNSIGNED,
  IN p_amount DECIMAL(12,2),
  IN p_reason VARCHAR(300),
  OUT o_refund_id BIGINT UNSIGNED,
  OUT o_refund_no VARCHAR(40)
)
BEGIN
  DECLARE v_payment_amount DECIMAL(12,2);
  DECLARE v_refunded_amount DECIMAL(12,2);
  DECLARE v_remaining DECIMAL(12,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_payment_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_id is required';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'amount must be > 0';
  END IF;

  START TRANSACTION;

  SELECT p.amount
    INTO v_payment_amount
  FROM payment p
  WHERE p.payment_id = p_payment_id
    AND p.status = 'SUCCESS'
  FOR UPDATE;

  IF v_payment_amount IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment not found or not SUCCESS';
  END IF;

  SELECT IFNULL(SUM(r.amount), 0.00)
    INTO v_refunded_amount
  FROM refund r
  WHERE r.payment_id = p_payment_id
    AND r.status = 'SUCCESS';

  SET v_remaining = ROUND(v_payment_amount - IFNULL(v_refunded_amount, 0.00), 2);

  IF p_amount > v_remaining THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'refund amount exceeds remaining refundable amount';
  END IF;

  SET o_refund_no = CONCAT('ref_', UUID_SHORT());
  INSERT INTO refund (
    refund_no,
    payment_id,
    amount,
    reason,
    status
  )
  VALUES (
    o_refund_no,
    p_payment_id,
    p_amount,
    p_reason,
    'SUCCESS'
  );

  SET o_refund_id = LAST_INSERT_ID();

  COMMIT;
END$$
