
CALL sp_seed_hospital(
  @department_count,
  @staff_count,
  @doctor_count,
  @pharmacist_count,
  @technician_count,
  @patient_count,
  @schedule_days,
  @slots_per_day,
  @reg_per_schedule,
  @admission_count,
  @drug_count,
  @lab_test_count,
  @rx_items_max,
  @lab_items_max,
  @staff_account_count,
  @patient_account_count,
  @invoice_pct,
  @payment_pct,
  @refund_pct
);

DROP PROCEDURE IF EXISTS sp_seed_hospital;

-- =========================
-- 简单核对（可选）
-- =========================

SELECT 'department' AS table_name, COUNT(*) AS cnt FROM department
UNION ALL SELECT 'staff', COUNT(*) FROM staff
UNION ALL SELECT 'patient', COUNT(*) FROM patient
UNION ALL SELECT 'doctor_schedule', COUNT(*) FROM doctor_schedule
UNION ALL SELECT 'registration', COUNT(*) FROM registration
UNION ALL SELECT 'encounter', COUNT(*) FROM encounter
UNION ALL SELECT 'prescription', COUNT(*) FROM prescription
UNION ALL SELECT 'lab_order', COUNT(*) FROM lab_order
UNION ALL SELECT 'charge', COUNT(*) FROM charge
UNION ALL SELECT 'invoice', COUNT(*) FROM invoice
UNION ALL SELECT 'payment', COUNT(*) FROM payment
UNION ALL SELECT 'refund', COUNT(*) FROM refund;
