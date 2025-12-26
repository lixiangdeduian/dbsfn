-- 医院管理系统（MySQL 9.x）- 触发器定义（已拆分）
USE hospital_test;

\. sql/triggers/00_preamble.sql
\. sql/triggers/10_audit.sql
\. sql/triggers/20_registration_quota.sql
\. sql/triggers/30_bed_assignment_no_overlap.sql
\. sql/triggers/40_diagnosis_primary_unique.sql
\. sql/triggers/50_amount_calc.sql
\. sql/triggers/60_invoice_line_recalc.sql
\. sql/triggers/70_refund_amount_check.sql
\. sql/triggers/80_payment_refund_update_invoice.sql
