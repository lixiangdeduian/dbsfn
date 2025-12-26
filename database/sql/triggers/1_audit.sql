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

