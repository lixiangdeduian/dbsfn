-- 医院管理系统（MySQL 9.x）- 角色 / 权限 / 视图设计
USE hospital_test;

-- =========================
-- 1) 角色定义
-- =========================

CREATE ROLE IF NOT EXISTS role_admin;
CREATE ROLE IF NOT EXISTS role_doctor;
CREATE ROLE IF NOT EXISTS role_nurse;
CREATE ROLE IF NOT EXISTS role_pharmacist;
CREATE ROLE IF NOT EXISTS role_lab_tech;
CREATE ROLE IF NOT EXISTS role_cashier;
CREATE ROLE IF NOT EXISTS role_reception;
CREATE ROLE IF NOT EXISTS role_patient;

-- =========================
-- 2) 视图定义（最小披露原则）
-- 说明：权限优先授予到视图；仅在需要写入时授予基表 DML 权限。
-- =========================

-- 患者公开信息视图（来源：patient）
-- 字段：patient_id, patient_no, patient_name, gender, birth_date, phone, blood_type
CREATE OR REPLACE VIEW v_patient_public
AS
SELECT
  p.patient_id,
  p.patient_no,
  p.patient_name,
  p.gender,
  p.birth_date,
  p.phone,
  p.blood_type
FROM patient p
WHERE p.is_active = 1;

-- 医生排班公开信息（来源：doctor_schedule + staff + department）
-- 字段：schedule_id, schedule_date, start_time, end_time, quota, registration_fee, doctor_id, doctor_name, department_id, department_name
CREATE OR REPLACE VIEW v_schedule_public
AS
SELECT
  s.schedule_id,
  s.schedule_date,
  s.start_time,
  s.end_time,
  s.quota,
  s.registration_fee,
  s.doctor_id,
  st.staff_name AS doctor_name,
  s.department_id,
  d.department_name
FROM doctor_schedule s
JOIN staff st ON st.staff_id = s.doctor_id
JOIN department d ON d.department_id = s.department_id
WHERE s.is_active = 1 AND st.is_active = 1 AND d.is_active = 1;

-- 就诊概要（来源：encounter + patient + department + staff）
-- 字段：encounter_id, encounter_no, encounter_type, started_at, ended_at, status, patient_id, patient_name, department_name, doctor_name
CREATE OR REPLACE VIEW v_encounter_summary
AS
SELECT
  e.encounter_id,
  e.encounter_no,
  e.encounter_type,
  e.started_at,
  e.ended_at,
  e.status,
  e.patient_id,
  p.patient_name,
  d.department_name,
  st.staff_name AS doctor_name
FROM encounter e
JOIN patient p ON p.patient_id = e.patient_id
JOIN department d ON d.department_id = e.department_id
JOIN staff st ON st.staff_id = e.doctor_id;

-- 处方明细视图（来源：prescription + prescription_item + drug）
-- 字段：prescription_id, prescription_no, issued_at, status, total_amount, encounter_id, doctor_id, item字段...
CREATE OR REPLACE VIEW v_prescription_detail
AS
SELECT
  pr.prescription_id,
  pr.prescription_no,
  pr.encounter_id,
  pr.doctor_id,
  pr.issued_at,
  pr.status,
  pr.total_amount,
  pi.prescription_item_id,
  pi.drug_id,
  d.drug_name,
  d.specification,
  d.unit,
  pi.quantity,
  pi.unit_price,
  pi.amount,
  pi.usage_instructions,
  pi.frequency,
  pi.days
FROM prescription pr
JOIN prescription_item pi ON pi.prescription_id = pr.prescription_id
JOIN drug d ON d.drug_id = pi.drug_id;

-- 检验结果视图（来源：lab_order + lab_order_item + lab_test + lab_result）
-- 字段：lab_order_id, lab_order_no, ordered_at, status, item字段..., result字段...
CREATE OR REPLACE VIEW v_lab_result_detail
AS
SELECT
  lo.lab_order_id,
  lo.lab_order_no,
  lo.encounter_id,
  lo.doctor_id,
  lo.ordered_at,
  lo.status AS order_status,
  li.lab_order_item_id,
  lt.lab_test_id,
  lt.test_code,
  lt.test_name,
  lt.unit,
  lt.reference_range,
  li.quantity,
  li.unit_price,
  li.amount,
  lr.lab_result_id,
  lr.result_value,
  lr.result_text,
  lr.result_flag,
  lr.result_at,
  lr.technician_id,
  lr.verified_by,
  lr.verified_at
FROM lab_order lo
JOIN lab_order_item li ON li.lab_order_id = lo.lab_order_id
JOIN lab_test lt ON lt.lab_test_id = li.lab_test_id
LEFT JOIN lab_result lr ON lr.lab_order_item_id = li.lab_order_item_id;

-- 发票概要（来源：invoice + patient）
-- 字段：invoice_id, invoice_no, issued_at, status, total_amount, paid_amount, patient_id, patient_name
CREATE OR REPLACE VIEW v_invoice_summary
AS
SELECT
  i.invoice_id,
  i.invoice_no,
  i.patient_id,
  p.patient_name,
  i.encounter_id,
  i.issued_at,
  i.status,
  i.total_amount,
  i.paid_amount,
  (i.total_amount - i.paid_amount) AS outstanding_amount
FROM invoice i
JOIN patient p ON p.patient_id = i.patient_id;

-- 发票明细（来源：invoice_line + charge + charge_catalog）
-- 字段：invoice_id, charge_id, charge_no, charged_at, amount, item_code, item_name, category
CREATE OR REPLACE VIEW v_invoice_detail
AS
SELECT
  il.invoice_id,
  c.charge_id,
  c.charge_no,
  c.encounter_id,
  c.source_type,
  c.source_id,
  c.charged_at,
  c.amount,
  cc.item_code,
  cc.item_name,
  cc.category
FROM invoice_line il
JOIN charge c ON c.charge_id = il.charge_id
JOIN charge_catalog cc ON cc.charge_item_id = c.charge_item_id;

-- =========================
-- 2.1) 患者自助视图（假设：DB 用户名 = user_account.username）
-- 说明：使用 SQL SECURITY INVOKER + CURRENT_USER() 做行级过滤（教学用）
-- =========================

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_current_patient
AS
SELECT
  p.patient_id,
  p.patient_no,
  p.patient_name,
  p.gender,
  p.birth_date,
  p.phone,
  p.address,
  p.blood_type,
  p.allergy_history
FROM user_account ua
JOIN patient p ON p.patient_id = ua.patient_id
WHERE ua.is_active = 1
  AND ua.username = SUBSTRING_INDEX(CURRENT_USER(), '@', 1);

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_patient_my_encounters
AS
SELECT es.*
FROM v_encounter_summary es
JOIN v_current_patient cp ON cp.patient_id = es.patient_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_patient_my_prescriptions
AS
SELECT pd.*
FROM v_prescription_detail pd
JOIN encounter e ON e.encounter_id = pd.encounter_id
JOIN v_current_patient cp ON cp.patient_id = e.patient_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_patient_my_lab_results
AS
SELECT lrd.*
FROM v_lab_result_detail lrd
JOIN encounter e ON e.encounter_id = lrd.encounter_id
JOIN v_current_patient cp ON cp.patient_id = e.patient_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_patient_my_invoices
AS
SELECT vis.*
FROM v_invoice_summary vis
JOIN v_current_patient cp ON cp.patient_id = vis.patient_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_patient_my_invoice_details
AS
SELECT vid.*
FROM v_invoice_detail vid
JOIN invoice i ON i.invoice_id = vid.invoice_id
JOIN v_current_patient cp ON cp.patient_id = i.patient_id;

-- =========================
-- 3) 权限设计（逐角色）
-- =========================
-- role_admin：
--   - 全库 ALL PRIVILEGES
GRANT ALL PRIVILEGES ON hospital_t.* TO role_admin;

-- role_reception（挂号/预约/基础信息维护）：
--   - 患者：增改查（不直接暴露敏感字段视图时，可按需改为仅基表部分字段）
--   - 排班/挂号：查询排班、创建挂号、查询挂号
GRANT SELECT ON hospital_t.v_schedule_public TO role_reception;
GRANT SELECT ON hospital_t.v_patient_public TO role_reception;
GRANT SELECT, INSERT, UPDATE ON hospital_t.patient TO role_reception;
GRANT SELECT, INSERT, UPDATE ON hospital_t.registration TO role_reception;

-- role_doctor（诊疗/处方/检验开单）：
GRANT SELECT ON hospital_t.v_patient_public TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.encounter TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.diagnosis TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.prescription TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.prescription_item TO role_doctor;
GRANT SELECT ON hospital_t.v_prescription_detail TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.lab_order TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_t.lab_order_item TO role_doctor;
GRANT SELECT ON hospital_t.v_lab_result_detail TO role_doctor;
GRANT SELECT ON hospital_t.v_encounter_summary TO role_doctor;

-- role_nurse（住院/病区/床位管理）：
GRANT SELECT ON hospital_t.v_patient_public TO role_nurse;
GRANT SELECT, INSERT, UPDATE ON hospital_t.admission TO role_nurse;
GRANT SELECT, INSERT, UPDATE ON hospital_t.bed_assignment TO role_nurse;
GRANT SELECT ON hospital_t.ward TO role_nurse;
GRANT SELECT ON hospital_t.bed TO role_nurse;

-- role_pharmacist（药品/调剂）：
GRANT SELECT, INSERT, UPDATE ON hospital_t.drug TO role_pharmacist;
GRANT SELECT ON hospital_t.v_prescription_detail TO role_pharmacist;
GRANT SELECT, INSERT, UPDATE ON hospital_t.dispense TO role_pharmacist;
GRANT SELECT, UPDATE ON hospital_t.prescription TO role_pharmacist;

-- role_lab_tech（检验结果录入/审核）：
GRANT SELECT ON hospital_t.v_patient_public TO role_lab_tech;
GRANT SELECT, UPDATE ON hospital_t.lab_order TO role_lab_tech;
GRANT SELECT ON hospital_t.lab_order_item TO role_lab_tech;
GRANT SELECT, INSERT, UPDATE ON hospital_t.lab_result TO role_lab_tech;
GRANT SELECT ON hospital_t.v_lab_result_detail TO role_lab_tech;

-- role_cashier（收费/结算/支付/退款）：
GRANT SELECT ON hospital_t.v_invoice_summary TO role_cashier;
GRANT SELECT ON hospital_t.v_invoice_detail TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_t.invoice TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_t.invoice_line TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_t.payment TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_t.refund TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_t.charge TO role_cashier;
GRANT SELECT ON hospital_t.charge_catalog TO role_cashier;

-- role_patient（患者自助）：
--   - 只读：自己的信息/就诊/处方/检验结果/账单
GRANT SELECT ON hospital_t.v_current_patient TO role_patient;
GRANT SELECT ON hospital_t.v_patient_my_encounters TO role_patient;
GRANT SELECT ON hospital_t.v_patient_my_prescriptions TO role_patient;
GRANT SELECT ON hospital_t.v_patient_my_lab_results TO role_patient;
GRANT SELECT ON hospital_t.v_patient_my_invoices TO role_patient;
GRANT SELECT ON hospital_t.v_patient_my_invoice_details TO role_patient;
