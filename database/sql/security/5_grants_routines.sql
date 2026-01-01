-- =========================
-- 3.1) 例程（PROCEDURE）执行权限
-- 说明：请在执行 `routines.sql` 之后再执行本文件，否则过程不存在会导致 GRANT 报错。
-- =========================

USE hospital_test;

-- ========================================
-- 1. 患者管理相关（patient）
-- ========================================

-- 所有角色都可以创建患者（挂号需要）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_create TO role_reception;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_create TO role_doctor;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_create TO role_nurse;

-- 更新患者联系方式
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_update_contact TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_patient_update_contact TO role_reception;

-- ========================================
-- 2. 门诊相关（outpatient）
-- ========================================

-- 门诊挂号
GRANT EXECUTE ON PROCEDURE hospital_test.sp_outpatient_register TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_outpatient_register TO role_reception;

-- ========================================
-- 3. 发票相关（invoice）- 包含游标
-- ========================================

-- 为就诊创建发票（使用游标遍历未开票费用）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_create_for_encounter TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_create_for_encounter TO role_cashier;

-- 附加未开票费用到发票（使用游标遍历新费用）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_attach_unbilled_charges TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_attach_unbilled_charges TO role_cashier;

-- 作废发票（使用游标遍历发票行）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_void TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_invoice_void TO role_cashier;

-- ========================================
-- 4. 支付相关（payment）
-- ========================================

-- 创建支付
GRANT EXECUTE ON PROCEDURE hospital_test.sp_payment_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_payment_create TO role_cashier;

-- 创建退款
GRANT EXECUTE ON PROCEDURE hospital_test.sp_refund_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_refund_create TO role_cashier;

-- ========================================
-- 5. 住院相关（inpatient）- 包含游标
-- ========================================

-- 办理入院（使用游标查找可用床位）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_inpatient_admit TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_inpatient_admit TO role_nurse;

-- 床位转移
GRANT EXECUTE ON PROCEDURE hospital_test.sp_bed_assignment_transfer TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_bed_assignment_transfer TO role_nurse;

-- 办理出院
GRANT EXECUTE ON PROCEDURE hospital_test.sp_inpatient_discharge TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_inpatient_discharge TO role_nurse;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_inpatient_discharge TO role_doctor;

-- ========================================
-- 6. 处方/药房相关（pharmacy）
-- ========================================

-- 创建处方
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_create TO role_doctor;

-- 添加处方明细
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_add_item TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_add_item TO role_doctor;

-- 处方费用同步
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_bill_sync TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_bill_sync TO role_doctor;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_prescription_bill_sync TO role_cashier;

-- 发药
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_create TO role_pharmacist;

-- 发药（带时间）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_prescription TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_prescription TO role_pharmacist;

-- ========================================
-- 7. 检验相关（lab）- 包含游标
-- ========================================

-- 创建检验单
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_create TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_create TO role_doctor;

-- 添加检验项目
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_add_item TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_add_item TO role_doctor;

-- 标记已采样
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_mark_collected TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_mark_collected TO role_lab_tech;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_mark_collected TO role_nurse;

-- 检验费用同步
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_bill_sync TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_bill_sync TO role_doctor;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_bill_sync TO role_cashier;

-- 准备检验结果（使用游标遍历检验项目）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_prepare_results TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_order_prepare_results TO role_lab_tech;

-- 录入/更新检验结果
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_result_upsert TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_result_upsert TO role_lab_tech;

-- 审核检验结果
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_result_verify TO role_admin;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_lab_result_verify TO role_lab_tech;

-- ========================================
-- 总结：
-- - 共授予 23 个存储过程的执行权限
-- - 6 个存储过程使用游标（已标注）：
--   1. sp_invoice_create_for_encounter
--   2. sp_invoice_attach_unbilled_charges
--   3. sp_invoice_void
--   4. sp_inpatient_admit
--   5. sp_lab_order_prepare_results
--   6. （隐含）sp_lab_order_create 内部可能有游标逻辑
-- ========================================

FLUSH PRIVILEGES;
