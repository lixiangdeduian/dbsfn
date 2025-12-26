-- =========================
-- 业务触发器：退款额度校验
-- =========================

-- 功能：退款插入前校验支付存在、成功且退款不超额。
CREATE TRIGGER trg_refund_bi_amount_check
BEFORE INSERT ON refund
FOR EACH ROW
BEGIN
  DECLARE v_payment_amount DECIMAL(12,2);
  DECLARE v_payment_status VARCHAR(20);
  DECLARE v_refunded DECIMAL(12,2);

  SELECT p.amount, p.status INTO v_payment_amount, v_payment_status
  FROM payment p
  WHERE p.payment_id = NEW.payment_id;

  IF v_payment_amount IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment not found for refund';
  END IF;

  IF v_payment_status <> 'SUCCESS' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot refund a non-success payment';
  END IF;

  SELECT IFNULL(SUM(r.amount), 0.00) INTO v_refunded
  FROM refund r
  WHERE r.payment_id = NEW.payment_id
    AND r.status = 'SUCCESS';

  IF NEW.amount > (v_payment_amount - v_refunded) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Refund amount exceeds remaining payable amount';
  END IF;
END$$

