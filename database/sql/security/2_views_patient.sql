-- =========================
-- 2.1) 患者自助视图（假设：DB 用户名 = user_account.username）
-- 说明：使用 SQL SECURITY DEFINER + CURRENT_USER() 做行级过滤（避免开放基表 SELECT 给患者）
-- =========================

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_current_patient
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
  AND ua.username = SUBSTRING_INDEX(USER(), '@', 1);

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_patient_my_encounters
AS
SELECT es.*
FROM v_encounter_summary es
JOIN v_current_patient cp ON cp.patient_id = es.patient_id;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_patient_my_prescriptions
AS
SELECT pd.*
FROM v_prescription_detail pd
JOIN encounter e ON e.encounter_id = pd.encounter_id
JOIN v_current_patient cp ON cp.patient_id = e.patient_id;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_patient_my_lab_results
AS
SELECT lrd.*
FROM v_lab_result_detail lrd
JOIN encounter e ON e.encounter_id = lrd.encounter_id
JOIN v_current_patient cp ON cp.patient_id = e.patient_id;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_patient_my_invoices
AS
SELECT vis.*
FROM v_invoice_summary vis
JOIN v_current_patient cp ON cp.patient_id = vis.patient_id;

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_patient_my_invoice_details
AS
SELECT vid.*
FROM v_invoice_detail vid
JOIN invoice i ON i.invoice_id = vid.invoice_id
JOIN v_current_patient cp ON cp.patient_id = i.patient_id;
