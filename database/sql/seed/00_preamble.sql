-- 医院管理系统（MySQL 9.x）- 大量初始化数据脚本
-- 建议执行顺序：schema.sql -> triggers.sql -> seed.sql -> security.sql
--
-- 说明：
-- - 脚本会 TRUNCATE 业务表并重新生成数据（可重复执行）。
-- - 数据规模可在下方参数区调整；默认约生成：数万挂号/就诊、数百住院、药品/检验目录等。

USE hospital_test;

SET sql_safe_updates = 0;
SET time_zone = '+00:00';

-- =========================
-- 参数区（按需修改）
-- =========================

SET @department_count = 20;
SET @staff_count = 300;
SET @doctor_count = 60;
SET @pharmacist_count = 20;
SET @technician_count = 20;
SET @patient_count = 10000;

SET @schedule_days = 14;
SET @slots_per_day = 2;
SET @reg_per_schedule = 20;

SET @admission_count = 800;
SET @drug_count = 300;
SET @lab_test_count = 120;

SET @rx_items_max = 4;
SET @lab_items_max = 3;

SET @staff_account_count = 80;
SET @patient_account_count = 200;

SET @invoice_pct = 70;  -- 0-100：生成发票覆盖率（按 encounter_id 取模）
SET @payment_pct = 60;  -- 0-100：生成支付覆盖率（按 invoice_id 取模）
SET @refund_pct = 5;    -- 0-100：生成退款覆盖率（按 payment_id 取模）

-- =========================
-- 主过程：生成数据
-- =========================

