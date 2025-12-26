-- 医院管理系统（MySQL 9.x）- 数据库结构设计（已拆分）
-- 建议执行顺序：schema.sql -> triggers.sql -> seed.sql(可选) -> security.sql

\. sql/schema/0_init.sql
\. sql/schema/1_org.sql
\. sql/schema/2_patient.sql
\. sql/schema/3_outpatient.sql
\. sql/schema/4_inpatient.sql
\. sql/schema/5_pharmacy.sql
\. sql/schema/6_lab.sql
\. sql/schema/7_billing.sql
