-- =========================
-- 3.1) 例程（PROCEDURE）执行权限
-- 说明：请在执行 `routines.sql` 之后再执行本文件，否则过程不存在会导致 GRANT 报错。
-- =========================

USE hospital_test;

-- 药房：发药（会联动处方状态与费用同步）
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_create TO role_pharmacist;
GRANT EXECUTE ON PROCEDURE hospital_test.sp_dispense_prescription TO role_pharmacist;
