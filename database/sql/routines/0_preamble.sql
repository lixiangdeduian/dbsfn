-- 医院管理系统（MySQL 9.x）- 后端调用例程（存储过程/游标）
USE hospital_test;

DELIMITER $$

-- 允许重复执行：先删除同名过程
DROP PROCEDURE IF EXISTS sp_patient_create$$
DROP PROCEDURE IF EXISTS sp_patient_update_contact$$
DROP PROCEDURE IF EXISTS sp_outpatient_register$$
DROP PROCEDURE IF EXISTS sp_invoice_create_for_encounter$$
DROP PROCEDURE IF EXISTS sp_invoice_attach_unbilled_charges$$
DROP PROCEDURE IF EXISTS sp_invoice_void$$
DROP PROCEDURE IF EXISTS sp_payment_create$$
DROP PROCEDURE IF EXISTS sp_refund_create$$
DROP PROCEDURE IF EXISTS sp_inpatient_admit$$
DROP PROCEDURE IF EXISTS sp_bed_assignment_transfer$$
DROP PROCEDURE IF EXISTS sp_inpatient_discharge$$
DROP PROCEDURE IF EXISTS sp_prescription_create$$
DROP PROCEDURE IF EXISTS sp_prescription_add_item$$
DROP PROCEDURE IF EXISTS sp_prescription_bill_sync$$
DROP PROCEDURE IF EXISTS sp_dispense_create$$
DROP PROCEDURE IF EXISTS sp_lab_order_create$$
DROP PROCEDURE IF EXISTS sp_lab_order_add_item$$
DROP PROCEDURE IF EXISTS sp_lab_order_mark_collected$$
DROP PROCEDURE IF EXISTS sp_lab_order_bill_sync$$
DROP PROCEDURE IF EXISTS sp_lab_order_prepare_results$$
DROP PROCEDURE IF EXISTS sp_lab_result_upsert$$
DROP PROCEDURE IF EXISTS sp_lab_result_verify$$
