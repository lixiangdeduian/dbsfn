-- 医院管理系统（MySQL 9.x）- 角色 / 权限 / 视图设计（已拆分）
USE hospital_test;

SOURCE sql/security/00_roles.sql
SOURCE sql/security/10_views_public.sql
SOURCE sql/security/20_views_patient.sql
SOURCE sql/security/30_grants.sql
