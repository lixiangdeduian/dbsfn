-- =========================
-- 例程：统计报表（游标示例）
-- =========================

-- 功能：按科室输出挂号/就诊/开票/费用统计（游标遍历科室，将结果写入临时表返回）。
-- 适用：运营看板/科室经营分析；支持按日期过滤。
DROP PROCEDURE IF EXISTS sp_stats_department_overview$$
CREATE PROCEDURE sp_stats_department_overview(
  IN p_start_date DATE,
  IN p_end_date DATE,
  OUT o_department_count INT,
  OUT o_total_encounters INT,
  OUT o_total_charge_amount DECIMAL(14,2)
)
BEGIN
  DECLARE v_start_date DATE;
  DECLARE v_end_date DATE;
  DECLARE v_department_id BIGINT UNSIGNED;
  DECLARE v_department_name VARCHAR(100);
  DECLARE v_registrations INT;
  DECLARE v_encounters INT;
  DECLARE v_open_invoices INT;
  DECLARE v_charge_amount DECIMAL(14,2);
  DECLARE v_done TINYINT DEFAULT 0;

  DECLARE cur_active_departments CURSOR FOR
    SELECT d.department_id, d.department_name
    FROM department d
    WHERE d.is_active = 1
    ORDER BY d.department_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  SET v_start_date = COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 6 DAY));
  SET v_end_date = COALESCE(p_end_date, CURDATE());

  IF v_end_date < v_start_date THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_end_date must be >= p_start_date';
  END IF;

  SET o_department_count = 0;
  SET o_total_encounters = 0;
  SET o_total_charge_amount = 0.00;

  DROP TEMPORARY TABLE IF EXISTS tmp_department_overview;
  CREATE TEMPORARY TABLE tmp_department_overview (
    department_id BIGINT UNSIGNED,
    department_name VARCHAR(100),
    registrations INT,
    encounters INT,
    open_invoices INT,
    charge_amount DECIMAL(14,2)
  ) ENGINE=MEMORY;

  OPEN cur_active_departments;
  dept_loop: LOOP
    FETCH cur_active_departments INTO v_department_id, v_department_name;
    IF v_done = 1 THEN
      LEAVE dept_loop;
    END IF;

    SELECT COUNT(*) INTO v_registrations
    FROM registration r
    JOIN doctor_schedule s ON r.schedule_id = s.schedule_id
    WHERE s.department_id = v_department_id
      AND r.status <> 'CANCELLED'
      AND DATE(r.registered_at) BETWEEN v_start_date AND v_end_date;

    SELECT COUNT(*) INTO v_encounters
    FROM encounter e
    WHERE e.department_id = v_department_id
      AND e.status <> 'CANCELLED'
      AND DATE(e.started_at) BETWEEN v_start_date AND v_end_date;

    SELECT COUNT(*) INTO v_open_invoices
    FROM invoice i
    JOIN encounter e ON e.encounter_id = i.encounter_id
    WHERE e.department_id = v_department_id
      AND i.status IN ('OPEN','PARTIALLY_PAID')
      AND DATE(i.issued_at) BETWEEN v_start_date AND v_end_date;

    SELECT IFNULL(SUM(c.amount), 0.00) INTO v_charge_amount
    FROM charge c
    JOIN encounter e ON e.encounter_id = c.encounter_id
    WHERE e.department_id = v_department_id
      AND c.status <> 'CANCELLED'
      AND DATE(c.charged_at) BETWEEN v_start_date AND v_end_date;

    INSERT INTO tmp_department_overview (
      department_id,
      department_name,
      registrations,
      encounters,
      open_invoices,
      charge_amount
    )
    VALUES (
      v_department_id,
      v_department_name,
      v_registrations,
      v_encounters,
      v_open_invoices,
      v_charge_amount
    );

    SET o_department_count = o_department_count + 1;
    SET o_total_encounters = o_total_encounters + v_encounters;
    SET o_total_charge_amount = o_total_charge_amount + v_charge_amount;
  END LOOP;
  CLOSE cur_active_departments;

  SELECT *
  FROM tmp_department_overview
  ORDER BY charge_amount DESC, encounters DESC, registrations DESC, department_id;
END$$

-- 功能：按日统计开票数量、支付/退款/净额趋势（游标遍历日期集合）。
-- 适用：财务/运营日报；默认近 7 天。
DROP PROCEDURE IF EXISTS sp_stats_billing_trend$$
CREATE PROCEDURE sp_stats_billing_trend(
  IN p_start_date DATE,
  IN p_end_date DATE,
  OUT o_day_count INT,
  OUT o_total_net_payment DECIMAL(14,2)
)
BEGIN
  DECLARE v_start_date DATE;
  DECLARE v_end_date DATE;
  DECLARE v_stat_date DATE;
  DECLARE v_invoice_count INT;
  DECLARE v_invoice_amount DECIMAL(14,2);
  DECLARE v_payment_amount DECIMAL(14,2);
  DECLARE v_refund_amount DECIMAL(14,2);
  DECLARE v_done TINYINT DEFAULT 0;

  DECLARE cur_stat_dates CURSOR FOR
    SELECT d.stat_date
    FROM tmp_billing_dates d
    ORDER BY d.stat_date;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  SET v_start_date = COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 6 DAY));
  SET v_end_date = COALESCE(p_end_date, CURDATE());

  IF v_end_date < v_start_date THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_end_date must be >= p_start_date';
  END IF;

  SET o_day_count = 0;
  SET o_total_net_payment = 0.00;

  DROP TEMPORARY TABLE IF EXISTS tmp_billing_trend;
  CREATE TEMPORARY TABLE tmp_billing_trend (
    stat_date DATE PRIMARY KEY,
    invoice_count INT,
    invoice_amount DECIMAL(14,2),
    payment_amount DECIMAL(14,2),
    refund_amount DECIMAL(14,2),
    net_payment DECIMAL(14,2)
  ) ENGINE=MEMORY;

  DROP TEMPORARY TABLE IF EXISTS tmp_billing_dates;
  CREATE TEMPORARY TABLE tmp_billing_dates (
    stat_date DATE PRIMARY KEY
  ) ENGINE=MEMORY;

  INSERT IGNORE INTO tmp_billing_dates (stat_date)
  SELECT DISTINCT DATE(i.issued_at)
  FROM invoice i
  WHERE DATE(i.issued_at) BETWEEN v_start_date AND v_end_date;

  INSERT IGNORE INTO tmp_billing_dates (stat_date)
  SELECT DISTINCT DATE(p.paid_at)
  FROM payment p
  WHERE p.status = 'SUCCESS'
    AND DATE(p.paid_at) BETWEEN v_start_date AND v_end_date;

  INSERT IGNORE INTO tmp_billing_dates (stat_date)
  SELECT DISTINCT DATE(r.refunded_at)
  FROM refund r
  WHERE r.status = 'SUCCESS'
    AND DATE(r.refunded_at) BETWEEN v_start_date AND v_end_date;

  OPEN cur_stat_dates;
  stat_loop: LOOP
    FETCH cur_stat_dates INTO v_stat_date;
    IF v_done = 1 THEN
      LEAVE stat_loop;
    END IF;

    SELECT COUNT(*), IFNULL(SUM(i.total_amount), 0.00)
      INTO v_invoice_count, v_invoice_amount
    FROM invoice i
    WHERE DATE(i.issued_at) = v_stat_date;

    SELECT IFNULL(SUM(p.amount), 0.00) INTO v_payment_amount
    FROM payment p
    WHERE p.status = 'SUCCESS'
      AND DATE(p.paid_at) = v_stat_date;

    SELECT IFNULL(SUM(r.amount), 0.00) INTO v_refund_amount
    FROM refund r
    WHERE r.status = 'SUCCESS'
      AND DATE(r.refunded_at) = v_stat_date;

    INSERT INTO tmp_billing_trend (
      stat_date,
      invoice_count,
      invoice_amount,
      payment_amount,
      refund_amount,
      net_payment
    )
    VALUES (
      v_stat_date,
      v_invoice_count,
      v_invoice_amount,
      v_payment_amount,
      v_refund_amount,
      v_payment_amount - v_refund_amount
    );

    SET o_day_count = o_day_count + 1;
    SET o_total_net_payment = o_total_net_payment + (v_payment_amount - v_refund_amount);
  END LOOP;
  CLOSE cur_stat_dates;

  SELECT stat_date,
         invoice_count,
         invoice_amount,
         payment_amount,
         refund_amount,
         net_payment
  FROM tmp_billing_trend
  ORDER BY stat_date;
END$$

-- 功能：按医生输出就诊/处方/检验工作量（游标遍历医生），用于运营报表。
-- 适用：日常工作量统计；支持按日期过滤。
DROP PROCEDURE IF EXISTS sp_stats_doctor_workload$$
CREATE PROCEDURE sp_stats_doctor_workload(
  IN p_start_date DATE,
  IN p_end_date DATE,
  OUT o_doctor_count INT,
  OUT o_total_encounters INT,
  OUT o_total_prescriptions INT,
  OUT o_total_lab_orders INT
)
BEGIN
  DECLARE v_start_date DATE;
  DECLARE v_end_date DATE;
  DECLARE v_doctor_id BIGINT UNSIGNED;
  DECLARE v_doctor_name VARCHAR(100);
  DECLARE v_encounters INT;
  DECLARE v_prescriptions INT;
  DECLARE v_lab_orders INT;
  DECLARE v_done TINYINT DEFAULT 0;

  DECLARE cur_doctors CURSOR FOR
    SELECT s.staff_id, s.staff_name
    FROM staff s
    WHERE s.is_active = 1
    ORDER BY s.staff_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  SET v_start_date = COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 6 DAY));
  SET v_end_date = COALESCE(p_end_date, CURDATE());

  IF v_end_date < v_start_date THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_end_date must be >= p_start_date';
  END IF;

  SET o_doctor_count = 0;
  SET o_total_encounters = 0;
  SET o_total_prescriptions = 0;
  SET o_total_lab_orders = 0;

  DROP TEMPORARY TABLE IF EXISTS tmp_doctor_workload;
  CREATE TEMPORARY TABLE tmp_doctor_workload (
    doctor_id BIGINT UNSIGNED,
    doctor_name VARCHAR(100),
    encounters INT,
    prescriptions INT,
    lab_orders INT
  ) ENGINE=MEMORY;

  OPEN cur_doctors;
  doc_loop: LOOP
    FETCH cur_doctors INTO v_doctor_id, v_doctor_name;
    IF v_done = 1 THEN
      LEAVE doc_loop;
    END IF;

    SELECT COUNT(*) INTO v_encounters
    FROM encounter e
    WHERE e.doctor_id = v_doctor_id
      AND e.status <> 'CANCELLED'
      AND DATE(e.started_at) BETWEEN v_start_date AND v_end_date;

    SELECT COUNT(*) INTO v_prescriptions
    FROM prescription p
    WHERE p.doctor_id = v_doctor_id
      AND DATE(p.created_at) BETWEEN v_start_date AND v_end_date;

    SELECT COUNT(*) INTO v_lab_orders
    FROM lab_order lo
    WHERE lo.doctor_id = v_doctor_id
      AND DATE(lo.created_at) BETWEEN v_start_date AND v_end_date;

    INSERT INTO tmp_doctor_workload (
      doctor_id,
      doctor_name,
      encounters,
      prescriptions,
      lab_orders
    )
    VALUES (
      v_doctor_id,
      v_doctor_name,
      v_encounters,
      v_prescriptions,
      v_lab_orders
    );

    SET o_doctor_count = o_doctor_count + 1;
    SET o_total_encounters = o_total_encounters + v_encounters;
    SET o_total_prescriptions = o_total_prescriptions + v_prescriptions;
    SET o_total_lab_orders = o_total_lab_orders + v_lab_orders;
  END LOOP;
  CLOSE cur_doctors;

  SELECT doctor_id,
         doctor_name,
         encounters,
         prescriptions,
         lab_orders
  FROM tmp_doctor_workload
  ORDER BY encounters DESC, prescriptions DESC, lab_orders DESC, doctor_id;
END$$

-- 功能：按患者汇总未结清发票金额与数量（游标遍历患者），用于应收监控。
DROP PROCEDURE IF EXISTS sp_stats_patient_outstanding$$
CREATE PROCEDURE sp_stats_patient_outstanding(
  IN p_start_date DATE,
  IN p_end_date DATE,
  OUT o_patient_count INT,
  OUT o_total_outstanding DECIMAL(14,2)
)
BEGIN
  DECLARE v_start_date DATE;
  DECLARE v_end_date DATE;
  DECLARE v_patient_id BIGINT UNSIGNED;
  DECLARE v_patient_name VARCHAR(100);
  DECLARE v_invoice_count INT;
  DECLARE v_outstanding DECIMAL(14,2);
  DECLARE v_done TINYINT DEFAULT 0;

  DECLARE cur_patients CURSOR FOR
    SELECT DISTINCT i.patient_id, p.patient_name
    FROM invoice i
    JOIN patient p ON p.patient_id = i.patient_id
    WHERE i.status IN ('OPEN','PARTIALLY_PAID')
      AND DATE(i.issued_at) BETWEEN v_start_date AND v_end_date
    ORDER BY i.patient_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  SET v_start_date = COALESCE(p_start_date, DATE_SUB(CURDATE(), INTERVAL 6 DAY));
  SET v_end_date = COALESCE(p_end_date, CURDATE());

  IF v_end_date < v_start_date THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_end_date must be >= p_start_date';
  END IF;

  SET o_patient_count = 0;
  SET o_total_outstanding = 0.00;

  DROP TEMPORARY TABLE IF EXISTS tmp_patient_outstanding;
  CREATE TEMPORARY TABLE tmp_patient_outstanding (
    patient_id BIGINT UNSIGNED,
    patient_name VARCHAR(100),
    invoice_count INT,
    outstanding_amount DECIMAL(14,2)
  ) ENGINE=MEMORY;

  OPEN cur_patients;
  patient_loop: LOOP
    FETCH cur_patients INTO v_patient_id, v_patient_name;
    IF v_done = 1 THEN
      LEAVE patient_loop;
    END IF;

    SELECT COUNT(*),
           IFNULL(SUM(i.total_amount - IFNULL(i.paid_amount, 0.00)), 0.00)
      INTO v_invoice_count, v_outstanding
    FROM invoice i
    WHERE i.patient_id = v_patient_id
      AND i.status IN ('OPEN','PARTIALLY_PAID')
      AND DATE(i.issued_at) BETWEEN v_start_date AND v_end_date;

    INSERT INTO tmp_patient_outstanding (
      patient_id,
      patient_name,
      invoice_count,
      outstanding_amount
    )
    VALUES (
      v_patient_id,
      v_patient_name,
      v_invoice_count,
      v_outstanding
    );

    SET o_patient_count = o_patient_count + 1;
    SET o_total_outstanding = o_total_outstanding + v_outstanding;
  END LOOP;
  CLOSE cur_patients;

  SELECT patient_id,
         patient_name,
         invoice_count,
         outstanding_amount
  FROM tmp_patient_outstanding
  ORDER BY outstanding_amount DESC, invoice_count DESC, patient_id;
END$$
