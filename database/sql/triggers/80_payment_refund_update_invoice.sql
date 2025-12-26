-- =========================
-- 业务触发器：支付/退款联动发票已付金额与状态
-- =========================

-- 功能：支付插入后联动重算发票已付金额与状态。
CREATE TRIGGER trg_payment_ai_update_invoice
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
  UPDATE invoice i
  SET
    i.paid_amount = (
      SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
      WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS'
    ) - (
      SELECT IFNULL(SUM(r.amount), 0.00)
      FROM refund r
      JOIN payment p2 ON p2.payment_id = r.payment_id
      WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS'
    ),
    i.status = CASE
      WHEN i.status = 'VOID' THEN 'VOID'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS')
      ) <= 0 THEN 'OPEN'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS')
      ) < i.total_amount THEN 'PARTIALLY_PAID'
      ELSE 'PAID'
    END
  WHERE i.invoice_id = NEW.invoice_id;
END$$

-- 功能：支付更新后联动重算相关发票已付金额与状态。
CREATE TRIGGER trg_payment_au_update_invoice
AFTER UPDATE ON payment
FOR EACH ROW
BEGIN
  IF OLD.invoice_id <> NEW.invoice_id THEN
    -- 重算旧发票
    UPDATE invoice i
    SET
      i.paid_amount = (
        SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
        WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS'
      ) - (
        SELECT IFNULL(SUM(r.amount), 0.00)
        FROM refund r
        JOIN payment p2 ON p2.payment_id = r.payment_id
        WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS'
      ),
      i.status = CASE
        WHEN i.status = 'VOID' THEN 'VOID'
        WHEN (
          (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS')
          - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS')
        ) <= 0 THEN 'OPEN'
        WHEN (
          (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS')
          - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS')
        ) < i.total_amount THEN 'PARTIALLY_PAID'
        ELSE 'PAID'
      END
    WHERE i.invoice_id = OLD.invoice_id;
  END IF;

  -- 重算新发票
  UPDATE invoice i
  SET
    i.paid_amount = (
      SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
      WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS'
    ) - (
      SELECT IFNULL(SUM(r.amount), 0.00)
      FROM refund r
      JOIN payment p2 ON p2.payment_id = r.payment_id
      WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS'
    ),
    i.status = CASE
      WHEN i.status = 'VOID' THEN 'VOID'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS')
      ) <= 0 THEN 'OPEN'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = NEW.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = NEW.invoice_id AND r.status = 'SUCCESS')
      ) < i.total_amount THEN 'PARTIALLY_PAID'
      ELSE 'PAID'
    END
  WHERE i.invoice_id = NEW.invoice_id;
END$$

-- 功能：支付删除后联动重算发票已付金额与状态。
CREATE TRIGGER trg_payment_ad_update_invoice
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
  UPDATE invoice i
  SET
    i.paid_amount = (
      SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
      WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS'
    ) - (
      SELECT IFNULL(SUM(r.amount), 0.00)
      FROM refund r
      JOIN payment p2 ON p2.payment_id = r.payment_id
      WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS'
    ),
    i.status = CASE
      WHEN i.status = 'VOID' THEN 'VOID'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS')
      ) <= 0 THEN 'OPEN'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = OLD.invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = OLD.invoice_id AND r.status = 'SUCCESS')
      ) < i.total_amount THEN 'PARTIALLY_PAID'
      ELSE 'PAID'
    END
  WHERE i.invoice_id = OLD.invoice_id;
END$$

-- 功能：退款插入后联动重算发票已付金额与状态。
CREATE TRIGGER trg_refund_ai_update_invoice
AFTER INSERT ON refund
FOR EACH ROW
BEGIN
  DECLARE v_invoice_id BIGINT UNSIGNED;
  SELECT p.invoice_id INTO v_invoice_id FROM payment p WHERE p.payment_id = NEW.payment_id;

  UPDATE invoice i
  SET
    i.paid_amount = (
      SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
      WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS'
    ) - (
      SELECT IFNULL(SUM(r.amount), 0.00)
      FROM refund r
      JOIN payment p2 ON p2.payment_id = r.payment_id
      WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS'
    ),
    i.status = CASE
      WHEN i.status = 'VOID' THEN 'VOID'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS')
      ) <= 0 THEN 'OPEN'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS')
      ) < i.total_amount THEN 'PARTIALLY_PAID'
      ELSE 'PAID'
    END
  WHERE i.invoice_id = v_invoice_id;
END$$

-- 功能：退款删除后联动重算发票已付金额与状态。
CREATE TRIGGER trg_refund_ad_update_invoice
AFTER DELETE ON refund
FOR EACH ROW
BEGIN
  DECLARE v_invoice_id BIGINT UNSIGNED;
  SELECT p.invoice_id INTO v_invoice_id FROM payment p WHERE p.payment_id = OLD.payment_id;

  UPDATE invoice i
  SET
    i.paid_amount = (
      SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p
      WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS'
    ) - (
      SELECT IFNULL(SUM(r.amount), 0.00)
      FROM refund r
      JOIN payment p2 ON p2.payment_id = r.payment_id
      WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS'
    ),
    i.status = CASE
      WHEN i.status = 'VOID' THEN 'VOID'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS')
      ) <= 0 THEN 'OPEN'
      WHEN (
        (SELECT IFNULL(SUM(p.amount), 0.00) FROM payment p WHERE p.invoice_id = v_invoice_id AND p.status = 'SUCCESS')
        - (SELECT IFNULL(SUM(r.amount), 0.00) FROM refund r JOIN payment p2 ON p2.payment_id = r.payment_id WHERE p2.invoice_id = v_invoice_id AND r.status = 'SUCCESS')
      ) < i.total_amount THEN 'PARTIALLY_PAID'
      ELSE 'PAID'
    END
  WHERE i.invoice_id = v_invoice_id;
END$$

DELIMITER ;
