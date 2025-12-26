-- 医院管理系统（MySQL 9.x）- 触发器定义
USE hospital_test;

DELIMITER $$

-- 允许重复执行：先删除同名触发器
DROP TRIGGER IF EXISTS trg_department_bi_audit$$
DROP TRIGGER IF EXISTS trg_department_bu_audit$$
DROP TRIGGER IF EXISTS trg_staff_bi_audit$$
DROP TRIGGER IF EXISTS trg_staff_bu_audit$$
DROP TRIGGER IF EXISTS trg_staff_department_bi_audit$$
DROP TRIGGER IF EXISTS trg_staff_department_bu_audit$$
DROP TRIGGER IF EXISTS trg_patient_bi_audit$$
DROP TRIGGER IF EXISTS trg_patient_bu_audit$$
DROP TRIGGER IF EXISTS trg_user_account_bi_audit$$
DROP TRIGGER IF EXISTS trg_user_account_bu_audit$$
DROP TRIGGER IF EXISTS trg_doctor_schedule_bi_audit$$
DROP TRIGGER IF EXISTS trg_doctor_schedule_bu_audit$$
DROP TRIGGER IF EXISTS trg_registration_bi_audit$$
DROP TRIGGER IF EXISTS trg_registration_bu_audit$$
DROP TRIGGER IF EXISTS trg_encounter_bi_audit$$
DROP TRIGGER IF EXISTS trg_encounter_bu_audit$$
DROP TRIGGER IF EXISTS trg_diagnosis_bi_audit$$
DROP TRIGGER IF EXISTS trg_diagnosis_bu_audit$$
DROP TRIGGER IF EXISTS trg_ward_bi_audit$$
DROP TRIGGER IF EXISTS trg_ward_bu_audit$$
DROP TRIGGER IF EXISTS trg_bed_bi_audit$$
DROP TRIGGER IF EXISTS trg_bed_bu_audit$$
DROP TRIGGER IF EXISTS trg_admission_bi_audit$$
DROP TRIGGER IF EXISTS trg_admission_bu_audit$$
DROP TRIGGER IF EXISTS trg_bed_assignment_bi_audit$$
DROP TRIGGER IF EXISTS trg_bed_assignment_bu_audit$$
DROP TRIGGER IF EXISTS trg_drug_bi_audit$$
DROP TRIGGER IF EXISTS trg_drug_bu_audit$$
DROP TRIGGER IF EXISTS trg_prescription_bi_audit$$
DROP TRIGGER IF EXISTS trg_prescription_bu_audit$$
DROP TRIGGER IF EXISTS trg_prescription_item_bi_audit$$
DROP TRIGGER IF EXISTS trg_prescription_item_bu_audit$$
DROP TRIGGER IF EXISTS trg_dispense_bi_audit$$
DROP TRIGGER IF EXISTS trg_dispense_bu_audit$$
DROP TRIGGER IF EXISTS trg_lab_test_bi_audit$$
DROP TRIGGER IF EXISTS trg_lab_test_bu_audit$$
DROP TRIGGER IF EXISTS trg_lab_order_bi_audit$$
DROP TRIGGER IF EXISTS trg_lab_order_bu_audit$$
DROP TRIGGER IF EXISTS trg_lab_order_item_bi_audit$$
DROP TRIGGER IF EXISTS trg_lab_order_item_bu_audit$$
DROP TRIGGER IF EXISTS trg_lab_result_bi_audit$$
DROP TRIGGER IF EXISTS trg_lab_result_bu_audit$$
DROP TRIGGER IF EXISTS trg_charge_catalog_bi_audit$$
DROP TRIGGER IF EXISTS trg_charge_catalog_bu_audit$$
DROP TRIGGER IF EXISTS trg_charge_bi_audit$$
DROP TRIGGER IF EXISTS trg_charge_bu_audit$$
DROP TRIGGER IF EXISTS trg_invoice_bi_audit$$
DROP TRIGGER IF EXISTS trg_invoice_bu_audit$$
DROP TRIGGER IF EXISTS trg_invoice_line_bi_audit$$
DROP TRIGGER IF EXISTS trg_invoice_line_bu_audit$$
DROP TRIGGER IF EXISTS trg_payment_bi_audit$$
DROP TRIGGER IF EXISTS trg_payment_bu_audit$$
DROP TRIGGER IF EXISTS trg_refund_bi_audit$$
DROP TRIGGER IF EXISTS trg_refund_bu_audit$$
DROP TRIGGER IF EXISTS trg_registration_bi_quota_check$$
DROP TRIGGER IF EXISTS trg_bed_assignment_bi_no_overlap$$
DROP TRIGGER IF EXISTS trg_bed_assignment_bu_no_overlap$$
DROP TRIGGER IF EXISTS trg_diagnosis_bi_primary_unique$$
DROP TRIGGER IF EXISTS trg_diagnosis_bu_primary_unique$$
DROP TRIGGER IF EXISTS trg_prescription_item_bi_calc_amount$$
DROP TRIGGER IF EXISTS trg_prescription_item_bu_calc_amount$$
DROP TRIGGER IF EXISTS trg_prescription_item_ai_update_total$$
DROP TRIGGER IF EXISTS trg_prescription_item_au_update_total$$
DROP TRIGGER IF EXISTS trg_prescription_item_ad_update_total$$
DROP TRIGGER IF EXISTS trg_lab_order_item_bi_calc_amount$$
DROP TRIGGER IF EXISTS trg_lab_order_item_bu_calc_amount$$
DROP TRIGGER IF EXISTS trg_lab_order_item_ai_update_total$$
DROP TRIGGER IF EXISTS trg_lab_order_item_au_update_total$$
DROP TRIGGER IF EXISTS trg_lab_order_item_ad_update_total$$
DROP TRIGGER IF EXISTS trg_charge_bi_calc_amount$$
DROP TRIGGER IF EXISTS trg_charge_bu_calc_amount$$
DROP TRIGGER IF EXISTS trg_invoice_line_ai_recalc$$
DROP TRIGGER IF EXISTS trg_invoice_line_ad_recalc$$
DROP TRIGGER IF EXISTS trg_refund_bi_amount_check$$
DROP TRIGGER IF EXISTS trg_payment_ai_update_invoice$$
DROP TRIGGER IF EXISTS trg_payment_au_update_invoice$$
DROP TRIGGER IF EXISTS trg_payment_ad_update_invoice$$
DROP TRIGGER IF EXISTS trg_refund_ai_update_invoice$$
DROP TRIGGER IF EXISTS trg_refund_ad_update_invoice$$

-- =========================
-- 通用：审计字段（created_by/updated_by）
-- 说明：created_at/updated_at 由默认值与 ON UPDATE 自动维护
-- =========================

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_department_bi_audit
BEFORE INSERT ON department
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_department_bu_audit
BEFORE UPDATE ON department
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_staff_bi_audit
BEFORE INSERT ON staff
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_staff_bu_audit
BEFORE UPDATE ON staff
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_staff_department_bi_audit
BEFORE INSERT ON staff_department
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_staff_department_bu_audit
BEFORE UPDATE ON staff_department
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_patient_bi_audit
BEFORE INSERT ON patient
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_patient_bu_audit
BEFORE UPDATE ON patient
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_user_account_bi_audit
BEFORE INSERT ON user_account
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_user_account_bu_audit
BEFORE UPDATE ON user_account
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_doctor_schedule_bi_audit
BEFORE INSERT ON doctor_schedule
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_doctor_schedule_bu_audit
BEFORE UPDATE ON doctor_schedule
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_registration_bi_audit
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_registration_bu_audit
BEFORE UPDATE ON registration
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_encounter_bi_audit
BEFORE INSERT ON encounter
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_encounter_bu_audit
BEFORE UPDATE ON encounter
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_diagnosis_bi_audit
BEFORE INSERT ON diagnosis
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_diagnosis_bu_audit
BEFORE UPDATE ON diagnosis
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_ward_bi_audit
BEFORE INSERT ON ward
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_ward_bu_audit
BEFORE UPDATE ON ward
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_bed_bi_audit
BEFORE INSERT ON bed
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_bed_bu_audit
BEFORE UPDATE ON bed
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_admission_bi_audit
BEFORE INSERT ON admission
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_admission_bu_audit
BEFORE UPDATE ON admission
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_bed_assignment_bi_audit
BEFORE INSERT ON bed_assignment
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_bed_assignment_bu_audit
BEFORE UPDATE ON bed_assignment
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_drug_bi_audit
BEFORE INSERT ON drug
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_drug_bu_audit
BEFORE UPDATE ON drug
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_prescription_bi_audit
BEFORE INSERT ON prescription
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_prescription_bu_audit
BEFORE UPDATE ON prescription
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_prescription_item_bi_audit
BEFORE INSERT ON prescription_item
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_prescription_item_bu_audit
BEFORE UPDATE ON prescription_item
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_dispense_bi_audit
BEFORE INSERT ON dispense
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_dispense_bu_audit
BEFORE UPDATE ON dispense
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_lab_test_bi_audit
BEFORE INSERT ON lab_test
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_lab_test_bu_audit
BEFORE UPDATE ON lab_test
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_lab_order_bi_audit
BEFORE INSERT ON lab_order
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_lab_order_bu_audit
BEFORE UPDATE ON lab_order
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_lab_order_item_bi_audit
BEFORE INSERT ON lab_order_item
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_lab_order_item_bu_audit
BEFORE UPDATE ON lab_order_item
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_lab_result_bi_audit
BEFORE INSERT ON lab_result
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_lab_result_bu_audit
BEFORE UPDATE ON lab_result
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_charge_catalog_bi_audit
BEFORE INSERT ON charge_catalog
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_charge_catalog_bu_audit
BEFORE UPDATE ON charge_catalog
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_charge_bi_audit
BEFORE INSERT ON charge
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_charge_bu_audit
BEFORE UPDATE ON charge
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_invoice_bi_audit
BEFORE INSERT ON invoice
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_invoice_bu_audit
BEFORE UPDATE ON invoice
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_invoice_line_bi_audit
BEFORE INSERT ON invoice_line
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_invoice_line_bu_audit
BEFORE UPDATE ON invoice_line
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_payment_bi_audit
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_payment_bu_audit
BEFORE UPDATE ON payment
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：插入前自动填充 created_by/updated_by 审计字段。
CREATE TRIGGER trg_refund_bi_audit
BEFORE INSERT ON refund
FOR EACH ROW
BEGIN
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

-- 功能：更新前自动填充 updated_by 审计字段。
CREATE TRIGGER trg_refund_bu_audit
BEFORE UPDATE ON refund
FOR EACH ROW
BEGIN
  IF NEW.updated_by IS NULL THEN SET NEW.updated_by = CURRENT_USER(); END IF;
END$$

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

-- =========================
-- 业务触发器：诊断主诊断唯一（同一就诊只能有一个 PRIMARY）
-- =========================

-- 功能：诊断插入前确保同一就诊仅有一个主诊断。
CREATE TRIGGER trg_diagnosis_bi_primary_unique
BEFORE INSERT ON diagnosis
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  IF NEW.diagnosis_type = 'PRIMARY' THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM diagnosis
    WHERE encounter_id = NEW.encounter_id
      AND diagnosis_type = 'PRIMARY';
    IF v_cnt > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Encounter already has a PRIMARY diagnosis';
    END IF;
  END IF;
END$$

-- 功能：诊断更新前确保同一就诊仅有一个主诊断。
CREATE TRIGGER trg_diagnosis_bu_primary_unique
BEFORE UPDATE ON diagnosis
FOR EACH ROW
BEGIN
  DECLARE v_cnt INT;
  IF NEW.diagnosis_type = 'PRIMARY' THEN
    SELECT COUNT(*)
      INTO v_cnt
    FROM diagnosis
    WHERE encounter_id = NEW.encounter_id
      AND diagnosis_type = 'PRIMARY'
      AND diagnosis_id <> OLD.diagnosis_id;
    IF v_cnt > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Encounter already has a PRIMARY diagnosis';
    END IF;
  END IF;
END$$

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
