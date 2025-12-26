-- 医院管理系统（MySQL 9.x）- 大量初始化数据脚本（已拆分）
-- 建议执行顺序：schema.sql -> triggers.sql -> seed.sql -> security.sql

SOURCE sql/seed/00_preamble.sql
SOURCE sql/seed/10_procedure.sql
SOURCE sql/seed/20_run.sql
