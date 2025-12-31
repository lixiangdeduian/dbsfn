-- =========================
-- 4) 创建用户账号并授予角色
-- 说明：为每个角色创建一个测试用户账号
-- =========================

USE hospital_test;

-- 创建用户（如果不存在）
-- 注意：密码仅用于测试，生产环境应使用强密码

-- 管理员
CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'admin123';
GRANT role_admin TO 'admin_user'@'%';
SET DEFAULT ROLE role_admin TO 'admin_user'@'%';

-- 医生
CREATE USER IF NOT EXISTS 'doctor_user'@'%' IDENTIFIED BY 'doctor123';
GRANT role_doctor TO 'doctor_user'@'%';
SET DEFAULT ROLE role_doctor TO 'doctor_user'@'%';

-- 护士
CREATE USER IF NOT EXISTS 'nurse_user'@'%' IDENTIFIED BY 'nurse123';
GRANT role_nurse TO 'nurse_user'@'%';
SET DEFAULT ROLE role_nurse TO 'nurse_user'@'%';

-- 药剂师
CREATE USER IF NOT EXISTS 'pharmacist_user'@'%' IDENTIFIED BY 'pharmacist123';
GRANT role_pharmacist TO 'pharmacist_user'@'%';
SET DEFAULT ROLE role_pharmacist TO 'pharmacist_user'@'%';

-- 检验技师
CREATE USER IF NOT EXISTS 'lab_tech_user'@'%' IDENTIFIED BY 'labtech123';
GRANT role_lab_tech TO 'lab_tech_user'@'%';
SET DEFAULT ROLE role_lab_tech TO 'lab_tech_user'@'%';

-- 收费员
CREATE USER IF NOT EXISTS 'cashier_user'@'%' IDENTIFIED BY 'cashier123';
GRANT role_cashier TO 'cashier_user'@'%';
SET DEFAULT ROLE role_cashier TO 'cashier_user'@'%';

-- 前台接待
CREATE USER IF NOT EXISTS 'reception_user'@'%' IDENTIFIED BY 'reception123';
GRANT role_reception TO 'reception_user'@'%';
SET DEFAULT ROLE role_reception TO 'reception_user'@'%';

-- 患者
CREATE USER IF NOT EXISTS 'patient_user'@'%' IDENTIFIED BY 'patient123';
GRANT role_patient TO 'patient_user'@'%';
SET DEFAULT ROLE role_patient TO 'patient_user'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

