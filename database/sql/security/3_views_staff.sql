-- =========================
-- 2.0) 员工/角色视图（面向各业务角色的查询入口）
-- 说明：
-- - 尽量用视图承载常用 JOIN，便于权限按视图授予。
-- - 使用 SQL SECURITY DEFINER，避免为业务角色开放底层敏感基表的 SELECT。
-- - “当前员工”规则：假设 DB 用户名 = user_account.username（去掉 @host）。
-- =========================

-- 当前登录员工（来源：user_account + staff + staff_department + department）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_current_staff
AS
SELECT
  s.staff_id,
  s.staff_no,
  s.staff_name,
  s.title,
  s.phone,
  s.email,
  sd.department_id AS primary_department_id,
  d.department_name AS primary_department_name,
  s.is_active
FROM user_account ua
JOIN staff s ON s.staff_id = ua.staff_id
LEFT JOIN staff_department sd ON sd.staff_id = s.staff_id AND sd.is_primary = 1
LEFT JOIN department d ON d.department_id = sd.department_id
WHERE ua.is_active = 1
  AND ua.staff_id IS NOT NULL
  AND ua.username = SUBSTRING_INDEX(USER(), '@', 1);

-- 当前员工所在科室列表（来源：staff_department + department）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_current_staff_departments
AS
SELECT
  sd.staff_id,
  sd.department_id,
  d.department_code,
  d.department_name,
  sd.is_primary
FROM v_current_staff cs
JOIN staff_department sd ON sd.staff_id = cs.staff_id
JOIN department d ON d.department_id = sd.department_id
WHERE d.is_active = 1;

-- 接诊/前台可用：患者信息（比 public 稍多，但仍不暴露过敏史等医疗敏感字段）
CREATE OR REPLACE VIEW v_patient_reception
AS
SELECT
  p.patient_id,
  p.patient_no,
  p.patient_name,
  p.gender,
  p.birth_date,
  p.id_card_no,
  p.phone,
  p.address,
  p.emergency_contact_name,
  p.emergency_contact_phone,
  p.is_active,
  p.created_at,
  p.updated_at
FROM patient p
WHERE p.is_active = 1;

-- 临床可用：患者信息（医护可用，避免暴露证件号）
CREATE OR REPLACE VIEW v_patient_clinical
AS
SELECT
  p.patient_id,
  p.patient_no,
  p.patient_name,
  p.gender,
  p.birth_date,
  p.phone,
  p.address,
  p.emergency_contact_name,
  p.emergency_contact_phone,
  p.blood_type,
  p.allergy_history,
  p.is_active
FROM patient p
WHERE p.is_active = 1;

-- 药品目录（用于开方/药房查询）
CREATE OR REPLACE VIEW v_drug_catalog_active
AS
SELECT
  d.drug_id,
  d.drug_code,
  d.drug_name,
  d.specification,
  d.dosage_form,
  d.unit,
  d.manufacturer,
  d.unit_price,
  d.is_active
FROM drug d
WHERE d.is_active = 1;

-- 检验项目目录（用于开单/检验查询）
CREATE OR REPLACE VIEW v_lab_test_catalog_active
AS
SELECT
  lt.lab_test_id,
  lt.test_code,
  lt.test_name,
  lt.category,
  lt.specimen,
  lt.unit,
  lt.reference_range,
  lt.unit_price,
  lt.is_active
FROM lab_test lt
WHERE lt.is_active = 1;

-- 收费项目目录（用于收费员选取项目）
CREATE OR REPLACE VIEW v_charge_catalog_active
AS
SELECT
  cc.charge_item_id,
  cc.item_code,
  cc.item_name,
  cc.category,
  cc.unit,
  cc.unit_price,
  cc.is_active
FROM charge_catalog cc
WHERE cc.is_active = 1;

-- 挂号详情（来源：registration + patient + doctor_schedule + staff + department）
CREATE OR REPLACE VIEW v_registration_detail
AS
SELECT
  r.registration_id,
  r.registration_no,
  r.patient_id,
  p.patient_no,
  p.patient_name,
  p.gender,
  p.birth_date,
  p.phone,
  r.schedule_id,
  s.schedule_date,
  s.start_time,
  s.end_time,
  s.quota,
  s.registration_fee,
  s.doctor_id,
  st.staff_name AS doctor_name,
  s.department_id,
  d.department_name,
  r.registered_at,
  r.status,
  r.chief_complaint
FROM registration r
JOIN patient p ON p.patient_id = r.patient_id
JOIN doctor_schedule s ON s.schedule_id = r.schedule_id
JOIN staff st ON st.staff_id = s.doctor_id
JOIN department d ON d.department_id = s.department_id;

-- 就诊详情（来源：encounter + patient + department + staff + registration + doctor_schedule）
CREATE OR REPLACE VIEW v_encounter_detail
AS
SELECT
  e.encounter_id,
  e.encounter_no,
  e.encounter_type,
  e.status,
  e.started_at,
  e.ended_at,
  e.note AS encounter_note,
  e.patient_id,
  p.patient_no,
  p.patient_name,
  e.department_id,
  d.department_name,
  e.doctor_id,
  st.staff_name AS doctor_name,
  e.registration_id,
  r.registration_no,
  r.registered_at,
  r.status AS registration_status,
  r.chief_complaint,
  ds.schedule_date,
  ds.start_time,
  ds.end_time
FROM encounter e
JOIN patient p ON p.patient_id = e.patient_id
JOIN department d ON d.department_id = e.department_id
JOIN staff st ON st.staff_id = e.doctor_id
LEFT JOIN registration r ON r.registration_id = e.registration_id
LEFT JOIN doctor_schedule ds ON ds.schedule_id = r.schedule_id;

-- 就诊诊断详情（来源：diagnosis + encounter + patient）
CREATE OR REPLACE VIEW v_encounter_diagnosis_detail
AS
SELECT
  dg.diagnosis_id,
  dg.encounter_id,
  e.encounter_no,
  e.encounter_type,
  e.status AS encounter_status,
  e.patient_id,
  p.patient_name,
  dg.doctor_id,
  s.staff_name AS doctor_name,
  dg.diagnosis_code,
  dg.diagnosis_name,
  dg.diagnosis_type,
  dg.diagnosed_at,
  dg.note
FROM diagnosis dg
JOIN encounter e ON e.encounter_id = dg.encounter_id
JOIN patient p ON p.patient_id = e.patient_id
JOIN staff s ON s.staff_id = dg.doctor_id;

-- 在院住院清单（来源：admission + patient + department + staff + bed_assignment + bed + ward）
CREATE OR REPLACE VIEW v_inpatient_current
AS
SELECT
  a.admission_id,
  a.admission_no,
  a.status,
  a.patient_id,
  p.patient_no,
  p.patient_name,
  a.department_id,
  d.department_name,
  a.attending_doctor_id,
  st.staff_name AS attending_doctor_name,
  a.admitted_at,
  a.discharged_at,
  a.note AS admission_note,
  ba.bed_assignment_id,
  ba.start_at AS bed_start_at,
  ba.end_at AS bed_end_at,
  b.bed_id,
  b.bed_no,
  w.ward_id,
  w.ward_name
FROM admission a
JOIN patient p ON p.patient_id = a.patient_id
JOIN department d ON d.department_id = a.department_id
JOIN staff st ON st.staff_id = a.attending_doctor_id
LEFT JOIN bed_assignment ba ON ba.admission_id = a.admission_id AND ba.end_at IS NULL
LEFT JOIN bed b ON b.bed_id = ba.bed_id
LEFT JOIN ward w ON w.ward_id = b.ward_id
WHERE a.status = 'ADMITTED';

-- 床位占用视图（来源：bed + ward + department + bed_assignment + admission + patient）
CREATE OR REPLACE VIEW v_bed_occupancy
AS
SELECT
  b.bed_id,
  b.bed_no,
  b.status AS bed_status,
  w.ward_id,
  w.ward_name,
  d.department_id,
  d.department_name,
  ba.bed_assignment_id,
  ba.start_at,
  ba.end_at,
  a.admission_id,
  a.admission_no,
  a.status AS admission_status,
  p.patient_id,
  p.patient_name
FROM bed b
JOIN ward w ON w.ward_id = b.ward_id
JOIN department d ON d.department_id = w.department_id
LEFT JOIN bed_assignment ba ON ba.bed_id = b.bed_id AND ba.end_at IS NULL
LEFT JOIN admission a ON a.admission_id = ba.admission_id
LEFT JOIN patient p ON p.patient_id = a.patient_id;

-- 药房待发药队列（来源：prescription + encounter + patient + dispense）
CREATE OR REPLACE VIEW v_pharmacy_dispense_queue
AS
SELECT
  pr.prescription_id,
  pr.prescription_no,
  pr.encounter_id,
  e.encounter_no,
  e.patient_id,
  p.patient_name,
  pr.doctor_id,
  s.staff_name AS doctor_name,
  pr.issued_at,
  pr.status,
  pr.total_amount,
  (SELECT COUNT(*) FROM prescription_item pi WHERE pi.prescription_id = pr.prescription_id) AS item_count
FROM prescription pr
JOIN encounter e ON e.encounter_id = pr.encounter_id
JOIN patient p ON p.patient_id = e.patient_id
JOIN staff s ON s.staff_id = pr.doctor_id
LEFT JOIN dispense dp ON dp.prescription_id = pr.prescription_id AND dp.status = 'DISPENSED'
WHERE pr.status = 'ISSUED'
  AND dp.dispense_id IS NULL;

-- 药房发药记录（来源：dispense + prescription + encounter + patient）
CREATE OR REPLACE VIEW v_pharmacy_dispense_detail
AS
SELECT
  dp.dispense_id,
  dp.status AS dispense_status,
  dp.dispensed_at,
  dp.pharmacist_id,
  st.staff_name AS pharmacist_name,
  dp.prescription_id,
  pr.prescription_no,
  pr.status AS prescription_status,
  pr.total_amount,
  e.encounter_id,
  e.encounter_no,
  p.patient_id,
  p.patient_name
FROM dispense dp
JOIN prescription pr ON pr.prescription_id = dp.prescription_id
JOIN encounter e ON e.encounter_id = pr.encounter_id
JOIN patient p ON p.patient_id = e.patient_id
JOIN staff st ON st.staff_id = dp.pharmacist_id;

-- 检验工作台（来源：lab_order_item + lab_order + lab_test + encounter + patient + lab_result）
CREATE OR REPLACE VIEW v_lab_worklist
AS
SELECT
  lo.lab_order_id,
  lo.lab_order_no,
  lo.status AS lab_order_status,
  lo.ordered_at,
  lo.encounter_id,
  e.encounter_no,
  e.department_id,
  d.department_name,
  e.patient_id,
  p.patient_name,
  lo.doctor_id,
  s.staff_name AS doctor_name,
  li.lab_order_item_id,
  lt.lab_test_id,
  lt.test_code,
  lt.test_name,
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
FROM lab_order_item li
JOIN lab_order lo ON lo.lab_order_id = li.lab_order_id
JOIN lab_test lt ON lt.lab_test_id = li.lab_test_id
JOIN encounter e ON e.encounter_id = lo.encounter_id
JOIN department d ON d.department_id = e.department_id
JOIN patient p ON p.patient_id = e.patient_id
JOIN staff s ON s.staff_id = lo.doctor_id
LEFT JOIN lab_result lr ON lr.lab_order_item_id = li.lab_order_item_id;

-- 收费费用明细（来源：charge + charge_catalog + encounter + patient + invoice_line + invoice）
CREATE OR REPLACE VIEW v_charge_detail
AS
SELECT
  c.charge_id,
  c.charge_no,
  c.status AS charge_status,
  c.charged_at,
  c.encounter_id,
  e.encounter_no,
  e.patient_id,
  p.patient_name,
  c.source_type,
  c.source_id,
  c.charge_item_id,
  cc.item_code,
  cc.item_name,
  cc.category,
  c.quantity,
  c.unit_price,
  c.amount,
  i.invoice_id,
  i.invoice_no,
  i.status AS invoice_status
FROM charge c
JOIN charge_catalog cc ON cc.charge_item_id = c.charge_item_id
JOIN encounter e ON e.encounter_id = c.encounter_id
JOIN patient p ON p.patient_id = e.patient_id
LEFT JOIN invoice_line il ON il.charge_id = c.charge_id
LEFT JOIN invoice i ON i.invoice_id = il.invoice_id;

-- 支付/退款流水（来源：payment + refund + invoice + patient）
CREATE OR REPLACE VIEW v_payment_refund_detail
AS
SELECT
  i.invoice_id,
  i.invoice_no,
  i.status AS invoice_status,
  i.total_amount,
  i.paid_amount,
  i.patient_id,
  p.patient_name,
  pay.payment_id,
  pay.payment_no,
  pay.method,
  pay.amount AS payment_amount,
  pay.paid_at,
  pay.status AS payment_status,
  pay.transaction_ref,
  r.refund_id,
  r.refund_no,
  r.amount AS refund_amount,
  r.refunded_at,
  r.status AS refund_status,
  r.reason
FROM invoice i
JOIN patient p ON p.patient_id = i.patient_id
LEFT JOIN payment pay ON pay.invoice_id = i.invoice_id
LEFT JOIN refund r ON r.payment_id = pay.payment_id;

-- 医生：我的排班（来源：doctor_schedule + department）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_schedule
AS
SELECT sp.*
FROM v_schedule_public sp
JOIN v_current_staff cs ON cs.staff_id = sp.doctor_id;

-- 医生：我的挂号（来源：v_registration_detail）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_registrations
AS
SELECT rd.*
FROM v_registration_detail rd
JOIN v_current_staff cs ON cs.staff_id = rd.doctor_id;

-- 医生：我的就诊（来源：v_encounter_detail）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_encounters
AS
SELECT ed.*
FROM v_encounter_detail ed
JOIN v_current_staff cs ON cs.staff_id = ed.doctor_id;

-- 医生：我的诊断（按就诊归属过滤，而非仅按诊断医生）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_encounter_diagnoses
AS
SELECT edd.*
FROM v_encounter_diagnosis_detail edd
JOIN encounter e ON e.encounter_id = edd.encounter_id
JOIN v_current_staff cs ON cs.staff_id = e.doctor_id;

-- 医生：我的处方明细（来源：v_prescription_detail）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_prescriptions_detail
AS
SELECT pd.*
FROM v_prescription_detail pd
JOIN v_current_staff cs ON cs.staff_id = pd.doctor_id;

-- 医生：我的检验结果（来源：v_lab_result_detail）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_doctor_my_lab_results
AS
SELECT lrd.*
FROM v_lab_result_detail lrd
JOIN v_current_staff cs ON cs.staff_id = lrd.doctor_id;

-- 护士：住院床位总览（可按当前员工科室过滤，若维护了 staff_department.is_primary）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_nurse_my_inpatients
AS
SELECT ic.*
FROM v_inpatient_current ic
JOIN v_current_staff cs
  ON cs.primary_department_id IS NULL OR cs.primary_department_id = ic.department_id;

-- 检验：我的待处理项目（技师 = 当前员工）
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_lab_my_items
AS
SELECT wl.*
FROM v_lab_worklist wl
JOIN v_current_staff cs
  ON wl.technician_id IS NULL OR wl.technician_id = cs.staff_id;

-- 收银：未开票费用（来源：v_charge_detail）
CREATE OR REPLACE VIEW v_cashier_unbilled_charges
AS
SELECT *
FROM v_charge_detail
WHERE charge_status = 'UNBILLED';
