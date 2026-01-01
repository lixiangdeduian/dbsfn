-- =========================
-- 3) 权限设计（逐角色）
-- =========================
-- role_admin：
--   - 全库 ALL PRIVILEGES
GRANT ALL PRIVILEGES ON hospital_test.* TO role_admin;

-- role_reception（挂号/预约/基础信息维护）：
--   - 患者：增改查（不直接暴露敏感字段视图时，可按需改为仅基表部分字段）
--   - 排班/挂号：查询排班、创建挂号、查询挂号
GRANT SELECT ON hospital_test.v_schedule_public TO role_reception;
GRANT SELECT ON hospital_test.v_patient_public TO role_reception;
GRANT SELECT, INSERT, UPDATE ON hospital_test.v_patient_reception TO role_reception;
GRANT SELECT ON hospital_test.v_registration_detail TO role_reception;
GRANT SELECT ON hospital_test.v_current_staff TO role_reception;
GRANT SELECT, INSERT, UPDATE ON hospital_test.registration TO role_reception;

-- role_doctor（诊疗/处方/检验开单）：
GRANT SELECT ON hospital_test.v_patient_public TO role_doctor;
GRANT SELECT ON hospital_test.v_patient_clinical TO role_doctor;
GRANT SELECT ON hospital_test.v_current_staff TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_schedule TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_registrations TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_encounters TO role_doctor;
GRANT SELECT ON hospital_test.v_encounter_detail TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_encounter_diagnoses TO role_doctor;
GRANT SELECT ON hospital_test.v_drug_catalog_active TO role_doctor;
GRANT SELECT ON hospital_test.v_lab_test_catalog_active TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.encounter TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.diagnosis TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.prescription TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.prescription_item TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_prescriptions_detail TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.lab_order TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON hospital_test.lab_order_item TO role_doctor;
GRANT SELECT ON hospital_test.v_doctor_my_lab_results TO role_doctor;
GRANT SELECT ON hospital_test.v_encounter_summary TO role_doctor;

-- role_nurse（住院/病区/床位管理）：
GRANT SELECT ON hospital_test.v_patient_public TO role_nurse;
GRANT SELECT ON hospital_test.v_patient_clinical TO role_nurse;
GRANT SELECT ON hospital_test.v_current_staff TO role_nurse;
GRANT SELECT ON hospital_test.v_inpatient_current TO role_nurse;
GRANT SELECT ON hospital_test.v_bed_occupancy TO role_nurse;
GRANT SELECT ON hospital_test.v_nurse_my_inpatients TO role_nurse;
GRANT SELECT, INSERT, UPDATE ON hospital_test.admission TO role_nurse;
GRANT SELECT, INSERT, UPDATE ON hospital_test.bed_assignment TO role_nurse;

-- role_pharmacist（药品/调剂）：
GRANT SELECT ON hospital_test.v_current_staff TO role_pharmacist;
GRANT SELECT, INSERT, UPDATE ON hospital_test.v_drug_catalog_active TO role_pharmacist;
GRANT SELECT ON hospital_test.v_prescription_detail TO role_pharmacist;
GRANT SELECT ON hospital_test.v_pharmacy_dispense_queue TO role_pharmacist;
GRANT SELECT ON hospital_test.v_pharmacy_dispense_detail TO role_pharmacist;
GRANT SELECT, INSERT, UPDATE ON hospital_test.dispense TO role_pharmacist;
GRANT SELECT, UPDATE ON hospital_test.prescription TO role_pharmacist;

-- role_lab_tech（检验结果录入/审核）：
GRANT SELECT ON hospital_test.v_patient_public TO role_lab_tech;
GRANT SELECT ON hospital_test.v_patient_clinical TO role_lab_tech;
GRANT SELECT ON hospital_test.v_current_staff TO role_lab_tech;
GRANT SELECT ON hospital_test.v_lab_worklist TO role_lab_tech;
GRANT SELECT ON hospital_test.v_lab_my_items TO role_lab_tech;
GRANT SELECT ON hospital_test.v_lab_test_catalog_active TO role_lab_tech;
GRANT SELECT, UPDATE ON hospital_test.lab_order TO role_lab_tech;
GRANT SELECT, INSERT, UPDATE ON hospital_test.lab_result TO role_lab_tech;
GRANT SELECT ON hospital_test.v_lab_result_detail TO role_lab_tech;

-- role_cashier（收费/结算/支付/退款）：
GRANT SELECT ON hospital_test.v_current_staff TO role_cashier;
GRANT SELECT ON hospital_test.v_charge_catalog_active TO role_cashier;
GRANT SELECT ON hospital_test.v_invoice_summary TO role_cashier;
GRANT SELECT ON hospital_test.v_invoice_detail TO role_cashier;
GRANT SELECT ON hospital_test.v_charge_detail TO role_cashier;
GRANT SELECT ON hospital_test.v_cashier_unbilled_charges TO role_cashier;
GRANT SELECT ON hospital_test.v_payment_refund_detail TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_test.invoice TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_test.invoice_line TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_test.payment TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_test.refund TO role_cashier;
GRANT SELECT, INSERT, UPDATE ON hospital_test.charge TO role_cashier;

-- role_patient（患者自助）：
--   - 只读：自己的信息/就诊/处方/检验结果/账单
GRANT SELECT ON hospital_test.v_current_patient TO role_patient;
GRANT SELECT ON hospital_test.v_patient_my_encounters TO role_patient;
GRANT SELECT ON hospital_test.v_patient_my_prescriptions TO role_patient;
GRANT SELECT ON hospital_test.v_patient_my_lab_results TO role_patient;
GRANT SELECT ON hospital_test.v_patient_my_invoices TO role_patient;
GRANT SELECT ON hospital_test.v_patient_my_invoice_details TO role_patient;
