-- 医院管理系统（MySQL 9.x）- 触发器定义（已拆分）
USE hospital_test;

SOURCE sql/triggers/00_preamble.sql
SOURCE sql/triggers/10_audit.sql
SOURCE sql/triggers/20_registration_quota.sql
SOURCE sql/triggers/30_bed_assignment_no_overlap.sql
SOURCE sql/triggers/40_diagnosis_primary_unique.sql
SOURCE sql/triggers/50_amount_calc.sql
SOURCE sql/triggers/60_invoice_line_recalc.sql
SOURCE sql/triggers/70_refund_amount_check.sql
SOURCE sql/triggers/80_payment_refund_update_invoice.sql
