-- =========================
-- 业务触发器：发票明细联动（总额与费用状态）
-- =========================

-- 功能：发票明细插入后更新费用状态并重算发票总额。
CREATE TRIGGER trg_invoice_line_ai_recalc
AFTER INSERT ON invoice_line
FOR EACH ROW
BEGIN
  UPDATE charge c
  SET c.status = 'BILLED'
  WHERE c.charge_id = NEW.charge_id;

  UPDATE invoice i
  SET i.total_amount = (
      SELECT IFNULL(SUM(c.amount), 0.00)
      FROM invoice_line il
      JOIN charge c ON c.charge_id = il.charge_id
      WHERE il.invoice_id = NEW.invoice_id
    )
  WHERE i.invoice_id = NEW.invoice_id;
END$$

-- 功能：发票明细删除后回退费用状态并重算发票总额。
CREATE TRIGGER trg_invoice_line_ad_recalc
AFTER DELETE ON invoice_line
FOR EACH ROW
BEGIN
  UPDATE charge c
  SET c.status = 'UNBILLED'
  WHERE c.charge_id = OLD.charge_id;

  UPDATE invoice i
  SET i.total_amount = (
      SELECT IFNULL(SUM(c.amount), 0.00)
      FROM invoice_line il
      JOIN charge c ON c.charge_id = il.charge_id
      WHERE il.invoice_id = OLD.invoice_id
    )
  WHERE i.invoice_id = OLD.invoice_id;
END$$

