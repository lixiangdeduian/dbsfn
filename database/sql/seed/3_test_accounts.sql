-- ==========================================
-- Test Account Data for Role-Based System
-- ==========================================
-- This file creates user_account records for each role,
-- linking them to existing staff or patient records.
--
-- NOTE: Execute this AFTER running seed.sql
-- ==========================================

USE hospital_test;

-- Delete old test accounts if they exist
DELETE FROM user_account WHERE username IN (
    'admin_user', 'doctor_user', 'nurse_user', 'pharmacist_user',
    'lab_tech_user', 'cashier_user', 'reception_user', 'patient_user'
);

-- ==========================================
-- 1. Admin Account
-- ==========================================
-- admin_user -> staff_id = 1 (stf_000001)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'admin_user', 'hashed_password_admin', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000001' LIMIT 1;

-- ==========================================
-- 2. Doctor Account
-- ==========================================
-- doctor_user -> staff_id = 2 (stf_000002)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'doctor_user', 'hashed_password_doctor', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000002' LIMIT 1;

-- ==========================================
-- 3. Nurse Account
-- ==========================================
-- nurse_user -> staff_id = 3 (stf_000003)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'nurse_user', 'hashed_password_nurse', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000003' LIMIT 1;

-- ==========================================
-- 4. Pharmacist Account
-- ==========================================
-- pharmacist_user -> staff_id = 4 (stf_000004)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'pharmacist_user', 'hashed_password_pharmacist', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000004' LIMIT 1;

-- ==========================================
-- 5. Lab Technician Account
-- ==========================================
-- lab_tech_user -> staff_id = 5 (stf_000005)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'lab_tech_user', 'hashed_password_labtech', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000005' LIMIT 1;

-- ==========================================
-- 6. Cashier Account
-- ==========================================
-- cashier_user -> staff_id = 6 (stf_000006)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'cashier_user', 'hashed_password_cashier', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000006' LIMIT 1;

-- ==========================================
-- 7. Reception Account
-- ==========================================
-- reception_user -> staff_id = 7 (stf_000007)
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'reception_user', 'hashed_password_reception', staff_id, NULL, 1, NOW()
FROM staff WHERE staff_no = 'stf_000007' LIMIT 1;

-- ==========================================
-- 8. Patient Account (IMPORTANT)
-- ==========================================
-- patient_user -> patient_id = 1 (pt_0000001)
-- This is the key account for testing patient portal
INSERT INTO user_account (username, password_hash, staff_id, patient_id, is_active, created_at)
SELECT 'patient_user', 'hashed_password_patient', NULL, patient_id, 1, NOW()
FROM patient WHERE patient_no = 'pt_0000001' LIMIT 1;

-- ==========================================
-- Verification
-- ==========================================
SELECT 
    '8 test accounts created successfully' AS message,
    COUNT(*) AS total_accounts
FROM user_account
WHERE username IN (
    'admin_user', 'doctor_user', 'nurse_user', 'pharmacist_user',
    'lab_tech_user', 'cashier_user', 'reception_user', 'patient_user'
);

SELECT 
    username,
    staff_id,
    patient_id,
    is_active,
    created_at
FROM user_account
WHERE username IN (
    'admin_user', 'doctor_user', 'nurse_user', 'pharmacist_user',
    'lab_tech_user', 'cashier_user', 'reception_user', 'patient_user'
)
ORDER BY 
    CASE username
        WHEN 'admin_user' THEN 1
        WHEN 'doctor_user' THEN 2
        WHEN 'nurse_user' THEN 3
        WHEN 'pharmacist_user' THEN 4
        WHEN 'lab_tech_user' THEN 5
        WHEN 'cashier_user' THEN 6
        WHEN 'reception_user' THEN 7
        WHEN 'patient_user' THEN 8
    END;
