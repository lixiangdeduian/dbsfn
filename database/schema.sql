-- 医院管理系统（MySQL 9.x）- 数据库结构设计（已拆分）
-- 建议执行顺序：schema.sql -> triggers.sql -> seed.sql(可选) -> security.sql

SOURCE sql/schema/00_init.sql
SOURCE sql/schema/10_org.sql
SOURCE sql/schema/20_patient.sql
SOURCE sql/schema/30_outpatient.sql
SOURCE sql/schema/40_inpatient.sql
SOURCE sql/schema/50_pharmacy.sql
SOURCE sql/schema/60_lab.sql
SOURCE sql/schema/70_billing.sql
