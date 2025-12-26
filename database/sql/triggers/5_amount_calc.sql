-- =========================
-- 业务触发器：金额计算（处方、检验、费用）
-- =========================

-- 功能：处方明细插入前补齐单价并计算明细金额。
CREATE TRIGGER trg_prescription_item_bi_calc_amount
BEFORE INSERT ON prescription_item
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT d.unit_price
      FROM drug d
      WHERE d.drug_id = NEW.drug_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

-- 功能：处方明细更新前补齐单价并计算明细金额。
CREATE TRIGGER trg_prescription_item_bu_calc_amount
BEFORE UPDATE ON prescription_item
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT d.unit_price
      FROM drug d
      WHERE d.drug_id = NEW.drug_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

-- 功能：处方明细插入后重算处方总金额。
CREATE TRIGGER trg_prescription_item_ai_update_total
AFTER INSERT ON prescription_item
FOR EACH ROW
BEGIN
  UPDATE prescription p
  SET p.total_amount = (
    SELECT IFNULL(SUM(pi.amount), 0.00) FROM prescription_item pi WHERE pi.prescription_id = NEW.prescription_id
  )
  WHERE p.prescription_id = NEW.prescription_id;
END$$

-- 功能：处方明细更新后重算处方总金额。
CREATE TRIGGER trg_prescription_item_au_update_total
AFTER UPDATE ON prescription_item
FOR EACH ROW
BEGIN
  UPDATE prescription p
  SET p.total_amount = (
    SELECT IFNULL(SUM(pi.amount), 0.00) FROM prescription_item pi WHERE pi.prescription_id = NEW.prescription_id
  )
  WHERE p.prescription_id = NEW.prescription_id;
END$$

-- 功能：处方明细删除后重算处方总金额。
CREATE TRIGGER trg_prescription_item_ad_update_total
AFTER DELETE ON prescription_item
FOR EACH ROW
BEGIN
  UPDATE prescription p
  SET p.total_amount = (
    SELECT IFNULL(SUM(pi.amount), 0.00) FROM prescription_item pi WHERE pi.prescription_id = OLD.prescription_id
  )
  WHERE p.prescription_id = OLD.prescription_id;
END$$

-- 功能：检验明细插入前补齐单价并计算明细金额。
CREATE TRIGGER trg_lab_order_item_bi_calc_amount
BEFORE INSERT ON lab_order_item
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT lt.unit_price
      FROM lab_test lt
      WHERE lt.lab_test_id = NEW.lab_test_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

-- 功能：检验明细更新前补齐单价并计算明细金额。
CREATE TRIGGER trg_lab_order_item_bu_calc_amount
BEFORE UPDATE ON lab_order_item
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT lt.unit_price
      FROM lab_test lt
      WHERE lt.lab_test_id = NEW.lab_test_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

-- 功能：检验明细插入后重算检验单总金额。
CREATE TRIGGER trg_lab_order_item_ai_update_total
AFTER INSERT ON lab_order_item
FOR EACH ROW
BEGIN
  UPDATE lab_order lo
  SET lo.total_amount = (
    SELECT IFNULL(SUM(li.amount), 0.00) FROM lab_order_item li WHERE li.lab_order_id = NEW.lab_order_id
  )
  WHERE lo.lab_order_id = NEW.lab_order_id;
END$$

-- 功能：检验明细更新后重算检验单总金额。
CREATE TRIGGER trg_lab_order_item_au_update_total
AFTER UPDATE ON lab_order_item
FOR EACH ROW
BEGIN
  UPDATE lab_order lo
  SET lo.total_amount = (
    SELECT IFNULL(SUM(li.amount), 0.00) FROM lab_order_item li WHERE li.lab_order_id = NEW.lab_order_id
  )
  WHERE lo.lab_order_id = NEW.lab_order_id;
END$$

-- 功能：检验明细删除后重算检验单总金额。
CREATE TRIGGER trg_lab_order_item_ad_update_total
AFTER DELETE ON lab_order_item
FOR EACH ROW
BEGIN
  UPDATE lab_order lo
  SET lo.total_amount = (
    SELECT IFNULL(SUM(li.amount), 0.00) FROM lab_order_item li WHERE li.lab_order_id = OLD.lab_order_id
  )
  WHERE lo.lab_order_id = OLD.lab_order_id;
END$$

-- 功能：费用插入前补齐单价并计算金额。
CREATE TRIGGER trg_charge_bi_calc_amount
BEFORE INSERT ON charge
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT cc.unit_price
      FROM charge_catalog cc
      WHERE cc.charge_item_id = NEW.charge_item_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

-- 功能：费用更新前补齐单价并计算金额。
CREATE TRIGGER trg_charge_bu_calc_amount
BEFORE UPDATE ON charge
FOR EACH ROW
BEGIN
  IF NEW.unit_price IS NULL THEN
    SET NEW.unit_price = (
      SELECT cc.unit_price
      FROM charge_catalog cc
      WHERE cc.charge_item_id = NEW.charge_item_id
    );
  END IF;
  SET NEW.amount = ROUND(NEW.quantity * NEW.unit_price, 2);
END$$

