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

