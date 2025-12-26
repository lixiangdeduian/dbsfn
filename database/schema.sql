-- 医院管理系统（MySQL 9.x）- 数据库结构设计（已拆分）
-- 建议执行顺序：schema.sql -> triggers.sql -> seed.sql(可选) -> security.sql

\. sql/schema/00_init.sql
\. sql/schema/10_org.sql
\. sql/schema/20_patient.sql
\. sql/schema/30_outpatient.sql
\. sql/schema/40_inpatient.sql
\. sql/schema/50_pharmacy.sql
\. sql/schema/60_lab.sql
\. sql/schema/70_billing.sql
