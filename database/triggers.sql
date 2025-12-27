-- 医院管理系统（MySQL 9.x）- 触发器定义（已拆分）
USE hospital_test;

\. sql/triggers/0_preamble.sql
\. sql/triggers/1_audit.sql
\. sql/triggers/2_registration_quota.sql
\. sql/triggers/3_bed_assignment_no_overlap.sql
\. sql/triggers/4_diagnosis_primary_unique.sql
\. sql/triggers/5_amount_calc.sql
\. sql/triggers/6_invoice_line_recalc.sql
\. sql/triggers/7_refund_amount_check.sql
\. sql/triggers/9_status_transitions.sql
\. sql/triggers/8_payment_refund_update_invoice.sql
