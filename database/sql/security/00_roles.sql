-- 医院管理系统（MySQL 9.x）- 角色 / 权限 / 视图设计
USE hospital_test;

-- =========================
-- 1) 角色定义
-- =========================

CREATE ROLE IF NOT EXISTS role_admin;
CREATE ROLE IF NOT EXISTS role_doctor;
CREATE ROLE IF NOT EXISTS role_nurse;
CREATE ROLE IF NOT EXISTS role_pharmacist;
CREATE ROLE IF NOT EXISTS role_lab_tech;
CREATE ROLE IF NOT EXISTS role_cashier;
CREATE ROLE IF NOT EXISTS role_reception;
CREATE ROLE IF NOT EXISTS role_patient;

