DELIMITER $$

DROP PROCEDURE IF EXISTS sp_seed_hospital$$
CREATE PROCEDURE sp_seed_hospital(
  IN p_department_count INT,
  IN p_staff_count INT,
  IN p_doctor_count INT,
  IN p_pharmacist_count INT,
  IN p_technician_count INT,
  IN p_patient_count INT,
  IN p_schedule_days INT,
  IN p_slots_per_day INT,
  IN p_reg_per_schedule INT,
  IN p_admission_count INT,
  IN p_drug_count INT,
  IN p_lab_test_count INT,
  IN p_rx_items_max INT,
  IN p_lab_items_max INT,
  IN p_staff_account_count INT,
  IN p_patient_account_count INT,
  IN p_invoice_pct INT,
  IN p_payment_pct INT,
  IN p_refund_pct INT
)
BEGIN
  DECLARE v_schedule_count BIGINT UNSIGNED;
  DECLARE v_registration_count BIGINT UNSIGNED;
  DECLARE v_max_seq BIGINT UNSIGNED;
  DECLARE v_ward_count INT;
  DECLARE v_beds_per_ward INT;
  DECLARE v_bed_count INT;
  DECLARE v_slot_time_1 TIME;
  DECLARE v_slot_time_2 TIME;
  DECLARE v_slot_time_3 TIME;

  DECLARE v_charge_item_reg BIGINT UNSIGNED;
  DECLARE v_charge_item_rx BIGINT UNSIGNED;
  DECLARE v_charge_item_lab BIGINT UNSIGNED;
  DECLARE v_charge_item_consult BIGINT UNSIGNED;

  IF p_department_count < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'department_count must be >= 1';
  END IF;

  IF p_staff_count < (p_doctor_count + p_pharmacist_count + p_technician_count) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'staff_count must be >= doctor_count + pharmacist_count + technician_count';
  END IF;

  IF p_patient_count < p_reg_per_schedule THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient_count must be >= reg_per_schedule (to avoid duplicate patient per schedule)';
  END IF;

  IF p_schedule_days < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'schedule_days must be >= 1';
  END IF;

  IF p_slots_per_day < 1 OR p_slots_per_day > 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'slots_per_day must be between 1 and 3';
  END IF;

  IF p_rx_items_max < 1 OR p_rx_items_max > 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rx_items_max must be between 1 and 10';
  END IF;

  IF p_lab_items_max < 1 OR p_lab_items_max > 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lab_items_max must be between 1 and 10';
  END IF;

  IF p_invoice_pct < 0 OR p_invoice_pct > 100 OR p_payment_pct < 0 OR p_payment_pct > 100 OR p_refund_pct < 0 OR p_refund_pct > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invoice/payment/refund pct must be 0-100';
  END IF;

  SET v_schedule_count = CAST(p_doctor_count AS UNSIGNED) * CAST(p_schedule_days AS UNSIGNED) * CAST(p_slots_per_day AS UNSIGNED);
  SET v_registration_count = v_schedule_count * CAST(p_reg_per_schedule AS UNSIGNED);

  SET v_ward_count = p_department_count;
  SET v_beds_per_ward = CEIL(p_admission_count / v_ward_count);
  SET v_bed_count = v_ward_count * v_beds_per_ward;

  IF v_bed_count < p_admission_count THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'internal error: bed_count < admission_count';
  END IF;

  SET v_max_seq = GREATEST(
    p_department_count,
    p_staff_count,
    p_patient_count,
    v_schedule_count,
    v_registration_count,
    p_admission_count,
    v_bed_count,
    p_drug_count,
    p_lab_test_count,
    p_rx_items_max,
    p_lab_items_max,
    p_staff_account_count,
    p_patient_account_count
  );

  SET v_slot_time_1 = '08:00:00';
  SET v_slot_time_2 = '13:00:00';
  SET v_slot_time_3 = '18:00:00';

  SET @@SESSION.cte_max_recursion_depth = CAST(LEAST(v_max_seq + 10, 1000000) AS SIGNED);

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_seq (
    n INT NOT NULL,
    PRIMARY KEY (n)
  ) ENGINE=Memory;

  TRUNCATE TABLE tmp_seq;

  INSERT INTO tmp_seq (n)
  WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < v_max_seq
  )
  SELECT n FROM seq;

  -- =========================
  -- 清空业务表（可重复执行）
  -- =========================

  SET FOREIGN_KEY_CHECKS = 0;

  TRUNCATE TABLE refund;
  TRUNCATE TABLE payment;
  TRUNCATE TABLE invoice_line;
  TRUNCATE TABLE invoice;
  TRUNCATE TABLE charge;
  TRUNCATE TABLE charge_catalog;

  TRUNCATE TABLE lab_result;
  TRUNCATE TABLE lab_order_item;
  TRUNCATE TABLE lab_order;
  TRUNCATE TABLE lab_test;

  TRUNCATE TABLE dispense;
  TRUNCATE TABLE prescription_item;
  TRUNCATE TABLE prescription;
  TRUNCATE TABLE drug;

  TRUNCATE TABLE bed_assignment;
  TRUNCATE TABLE admission;
  TRUNCATE TABLE bed;
  TRUNCATE TABLE ward;

  TRUNCATE TABLE diagnosis;
  TRUNCATE TABLE encounter;
  TRUNCATE TABLE registration;
  TRUNCATE TABLE doctor_schedule;

  TRUNCATE TABLE user_account;
  TRUNCATE TABLE patient;
  TRUNCATE TABLE staff_department;
  TRUNCATE TABLE staff;
  TRUNCATE TABLE department;

  SET FOREIGN_KEY_CHECKS = 1;

  -- =========================
  -- 基础目录：收费/药品/检验
  -- =========================

  INSERT INTO charge_catalog (
    item_code,
    item_name,
    category,
    unit,
    unit_price,
    is_active
  )
  VALUES
    ('REG_FEE', '挂号费', 'REGISTRATION', '次', 20.00, 1),
    ('CONSULT', '诊疗费', 'CONSULT', '次', 50.00, 1),
    ('RX_TOTAL', '药费（处方合计）', 'PHARMACY', '单', 0.00, 1),
    ('LAB_TOTAL', '检验费（检验单合计）', 'LAB', '单', 0.00, 1);

  SELECT charge_item_id INTO v_charge_item_reg FROM charge_catalog WHERE item_code = 'REG_FEE';
  SELECT charge_item_id INTO v_charge_item_consult FROM charge_catalog WHERE item_code = 'CONSULT';
  SELECT charge_item_id INTO v_charge_item_rx FROM charge_catalog WHERE item_code = 'RX_TOTAL';
  SELECT charge_item_id INTO v_charge_item_lab FROM charge_catalog WHERE item_code = 'LAB_TOTAL';

  INSERT INTO drug (
    drug_code,
    drug_name,
    specification,
    dosage_form,
    unit,
    manufacturer,
    unit_price,
    is_active
  )
  SELECT
    CONCAT('drug_', LPAD(s.n, 5, '0')),
    CONCAT('药品', s.n),
    CONCAT('规格', 1 + MOD(s.n, 5)),
    CASE MOD(s.n, 4)
      WHEN 0 THEN '片剂'
      WHEN 1 THEN '胶囊'
      WHEN 2 THEN '注射液'
      ELSE '口服液'
    END,
    CASE MOD(s.n, 3)
      WHEN 0 THEN '盒'
      WHEN 1 THEN '瓶'
      ELSE '支'
    END,
    CONCAT('厂家', 1 + MOD(s.n, 30)),
    ROUND(3 + MOD(s.n * 7, 500) / 10, 2),
    1
  FROM tmp_seq s
  WHERE s.n <= p_drug_count;

  INSERT INTO lab_test (
    test_code,
    test_name,
    category,
    specimen,
    unit,
    reference_range,
    unit_price,
    is_active
  )
  SELECT
    CONCAT('lab_', LPAD(s.n, 5, '0')),
    CONCAT('检验项目', s.n),
    CASE MOD(s.n, 5)
      WHEN 0 THEN '血常规'
      WHEN 1 THEN '生化'
      WHEN 2 THEN '免疫'
      WHEN 3 THEN '凝血'
      ELSE '尿常规'
    END,
    CASE MOD(s.n, 4)
      WHEN 0 THEN '血液'
      WHEN 1 THEN '尿液'
      WHEN 2 THEN '粪便'
      ELSE '其他'
    END,
    CASE MOD(s.n, 3)
      WHEN 0 THEN 'mg/L'
      WHEN 1 THEN 'mmol/L'
      ELSE 'U/L'
    END,
    '参考范围见报告',
    ROUND(10 + MOD(s.n * 11, 200) / 10, 2),
    1
  FROM tmp_seq s
  WHERE s.n <= p_lab_test_count;

  -- =========================
  -- 部门/人员/患者/账号
  -- =========================

  INSERT INTO department (
    department_code,
    department_name,
    parent_department_id,
    is_active
  )
  SELECT
    CONCAT('dept_', LPAD(s.n, 3, '0')),
    CONCAT('科室', s.n),
    NULL,
    1
  FROM tmp_seq s
  WHERE s.n <= p_department_count;

  -- 为部分科室设置上级科室（先插入后更新，避免自关联外键问题）
  UPDATE department d
  SET d.parent_department_id = 1 + MOD(d.department_id - 1, LEAST(5, p_department_count))
  WHERE d.department_id > LEAST(5, p_department_count);

  INSERT INTO staff (
    staff_no,
    staff_name,
    gender,
    phone,
    email,
    id_card_no,
    title,
    hire_date,
    is_active
  )
  SELECT
    CONCAT('stf_', LPAD(s.n, 6, '0')),
    CONCAT('员工', s.n),
    CASE MOD(s.n, 3)
      WHEN 0 THEN 'M'
      WHEN 1 THEN 'F'
      ELSE 'U'
    END,
    CONCAT('13', LPAD(100000000 + s.n, 9, '0')),
    CONCAT('staff', s.n, '@example.com'),
    CONCAT('idc_s_', LPAD(s.n, 12, '0')),
    CASE
      WHEN s.n <= p_doctor_count THEN 'Doctor'
      WHEN s.n <= p_doctor_count + p_pharmacist_count THEN 'Pharmacist'
      WHEN s.n <= p_doctor_count + p_pharmacist_count + p_technician_count THEN 'Technician'
      ELSE 'Nurse'
    END,
    DATE_SUB(CURDATE(), INTERVAL MOD(s.n * 17, 3650) DAY),
    1
  FROM tmp_seq s
  WHERE s.n <= p_staff_count;

  INSERT INTO staff_department (
    staff_id,
    department_id,
    is_primary
  )
  SELECT
    st.staff_id,
    1 + MOD(st.staff_id - 1, p_department_count),
    1
  FROM staff st;

  INSERT INTO patient (
    patient_no,
    patient_name,
    gender,
    birth_date,
    id_card_no,
    phone,
    address,
    emergency_contact_name,
    emergency_contact_phone,
    blood_type,
    allergy_history,
    is_active
  )
  SELECT
    CONCAT('pt_', LPAD(s.n, 7, '0')),
    CONCAT('患者', s.n),
    CASE MOD(s.n, 3)
      WHEN 0 THEN 'M'
      WHEN 1 THEN 'F'
      ELSE 'U'
    END,
    DATE_SUB(CURDATE(), INTERVAL (18 * 365 + MOD(s.n * 31, 60 * 365)) DAY),
    CONCAT('idc_p_', LPAD(s.n, 12, '0')),
    CONCAT('15', LPAD(100000000 + s.n, 9, '0')),
    CONCAT('地址', 1 + MOD(s.n, 2000)),
    CONCAT('联系人', 1 + MOD(s.n, 500)),
    CONCAT('16', LPAD(100000000 + MOD(s.n * 7, 999999999), 9, '0')),
    CASE MOD(s.n, 5)
      WHEN 0 THEN 'A'
      WHEN 1 THEN 'B'
      WHEN 2 THEN 'AB'
      WHEN 3 THEN 'O'
      ELSE 'U'
    END,
    CASE WHEN MOD(s.n, 10) = 0 THEN '青霉素' ELSE NULL END,
    1
  FROM tmp_seq s
  WHERE s.n <= p_patient_count;

  INSERT INTO user_account (
    username,
    password_hash,
    staff_id,
    patient_id,
    is_active,
    last_login_at
  )
  SELECT
    CONCAT('staff_', LPAD(s.n, 6, '0')),
    SHA2(CONCAT('pwd_staff_', s.n), 256),
    s.n,
    NULL,
    1,
    NULL
  FROM tmp_seq s
  WHERE s.n <= LEAST(p_staff_account_count, p_staff_count);

  INSERT INTO user_account (
    username,
    password_hash,
    staff_id,
    patient_id,
    is_active,
    last_login_at
  )
  SELECT
    CONCAT('patient_', LPAD(s.n, 7, '0')),
    SHA2(CONCAT('pwd_patient_', s.n), 256),
    NULL,
    s.n,
    1,
    NULL
  FROM tmp_seq s
  WHERE s.n <= LEAST(p_patient_account_count, p_patient_count);

  -- =========================
  -- 门诊：排班/挂号/就诊/诊断
  -- =========================

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_slot (
    slot_no INT NOT NULL,
    PRIMARY KEY (slot_no)
  ) ENGINE=Memory;

  TRUNCATE TABLE tmp_slot;

  INSERT INTO tmp_slot (slot_no)
  SELECT s.n
  FROM tmp_seq s
  WHERE s.n <= p_slots_per_day;

  INSERT INTO doctor_schedule (
    doctor_id,
    department_id,
    schedule_date,
    start_time,
    end_time,
    quota,
    registration_fee,
    is_active
  )
  SELECT
    d.staff_id,
    1 + MOD(d.staff_id - 1, p_department_count),
    DATE_ADD(CURDATE(), INTERVAL day_seq.n - 1 DAY),
    CASE slot.slot_no
      WHEN 1 THEN v_slot_time_1
      WHEN 2 THEN v_slot_time_2
      ELSE v_slot_time_3
    END,
    CASE slot.slot_no
      WHEN 1 THEN ADDTIME(v_slot_time_1, '04:00:00')
      WHEN 2 THEN ADDTIME(v_slot_time_2, '04:00:00')
      ELSE ADDTIME(v_slot_time_3, '03:00:00')
    END,
    p_reg_per_schedule,
    20.00,
    1
  FROM staff d
  JOIN tmp_seq day_seq ON day_seq.n <= p_schedule_days
  JOIN tmp_slot slot ON slot.slot_no <= p_slots_per_day
  WHERE d.staff_id <= p_doctor_count;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_reg_seq (
    rn INT NOT NULL,
    PRIMARY KEY (rn)
  ) ENGINE=Memory;

  TRUNCATE TABLE tmp_reg_seq;

  INSERT INTO tmp_reg_seq (rn)
  SELECT s.n
  FROM tmp_seq s
  WHERE s.n <= p_reg_per_schedule;

  INSERT INTO registration (
    registration_no,
    patient_id,
    schedule_id,
    registered_at,
    status,
    chief_complaint
  )
  SELECT
    CONCAT('reg_', LPAD(ds.schedule_id, 10, '0'), '_', LPAD(rn.rn, 3, '0')),
    1 + MOD((ds.schedule_id - 1) * p_reg_per_schedule + (rn.rn - 1), p_patient_count),
    ds.schedule_id,
    DATE_ADD(TIMESTAMP(ds.schedule_date, ds.start_time), INTERVAL MOD(rn.rn * 7, 240) MINUTE),
    'CONFIRMED',
    CASE MOD(rn.rn, 5)
      WHEN 0 THEN '咳嗽'
      WHEN 1 THEN '发热'
      WHEN 2 THEN '头痛'
      WHEN 3 THEN '腹痛'
      ELSE '复诊'
    END
  FROM doctor_schedule ds
  JOIN tmp_reg_seq rn ON 1 = 1
  WHERE ds.is_active = 1;

  INSERT INTO encounter (
    encounter_no,
    patient_id,
    department_id,
    doctor_id,
    registration_id,
    encounter_type,
    started_at,
    ended_at,
    status,
    note
  )
  SELECT
    CONCAT('enc_op_', LPAD(r.registration_id, 10, '0')),
    r.patient_id,
    ds.department_id,
    ds.doctor_id,
    r.registration_id,
    'OUTPATIENT',
    r.registered_at,
    DATE_ADD(r.registered_at, INTERVAL 15 MINUTE),
    'CLOSED',
    NULL
  FROM registration r
  JOIN doctor_schedule ds ON ds.schedule_id = r.schedule_id;

  INSERT INTO diagnosis (
    encounter_id,
    doctor_id,
    diagnosis_code,
    diagnosis_name,
    diagnosis_type,
    diagnosed_at,
    note
  )
  SELECT
    e.encounter_id,
    e.doctor_id,
    'J00',
    CASE MOD(e.encounter_id, 6)
      WHEN 0 THEN '上呼吸道感染'
      WHEN 1 THEN '胃炎'
      WHEN 2 THEN '高血压'
      WHEN 3 THEN '糖尿病'
      WHEN 4 THEN '过敏性鼻炎'
      ELSE '健康咨询'
    END,
    'PRIMARY',
    e.started_at,
    NULL
  FROM encounter e;

  INSERT INTO diagnosis (
    encounter_id,
    doctor_id,
    diagnosis_code,
    diagnosis_name,
    diagnosis_type,
    diagnosed_at,
    note
  )
  SELECT
    e.encounter_id,
    e.doctor_id,
    'Z00',
    '伴随症状',
    'SECONDARY',
    e.started_at,
    NULL
  FROM encounter e
  WHERE MOD(e.encounter_id, 3) = 0;

  -- =========================
  -- 住院：病区/床位/入院/床位分配 + 住院就诊记录
  -- =========================

  INSERT INTO ward (
    ward_code,
    ward_name,
    department_id,
    is_active
  )
  SELECT
    CONCAT('ward_', LPAD(s.n, 3, '0')),
    CONCAT('病区', s.n),
    s.n,
    1
  FROM tmp_seq s
  WHERE s.n <= v_ward_count;

  INSERT INTO bed (
    ward_id,
    bed_no,
    status
  )
  SELECT
    w.ward_id,
    CONCAT('bed_', LPAD(bn.n, 3, '0')),
    'AVAILABLE'
  FROM ward w
  JOIN tmp_seq bn ON bn.n <= v_beds_per_ward
  ORDER BY w.ward_id, bn.n;

  INSERT INTO admission (
    admission_no,
    patient_id,
    department_id,
    attending_doctor_id,
    admitted_at,
    discharged_at,
    status,
    note
  )
  SELECT
    CONCAT('adm_', LPAD(s.n, 10, '0')),
    1 + MOD((s.n * 13) - 1, p_patient_count),
    1 + MOD(s.n - 1, p_department_count),
    1 + MOD(s.n - 1, p_doctor_count),
    DATE_SUB(NOW(3), INTERVAL (1 + MOD(s.n * 3, 180)) DAY),
    CASE
      WHEN MOD(s.n, 2) = 0 THEN DATE_ADD(DATE_SUB(NOW(3), INTERVAL (1 + MOD(s.n * 3, 180)) DAY), INTERVAL (1 + MOD(s.n, 10)) DAY)
      ELSE NULL
    END,
    CASE
      WHEN MOD(s.n, 2) = 0 THEN 'DISCHARGED'
      ELSE 'ADMITTED'
    END,
    NULL
  FROM tmp_seq s
  WHERE s.n <= p_admission_count;

  INSERT INTO bed_assignment (
    admission_id,
    bed_id,
    start_at,
    end_at,
    note
  )
  SELECT
    a.admission_id,
    a.admission_id,
    a.admitted_at,
    a.discharged_at,
    NULL
  FROM admission a
  WHERE a.admission_id <= p_admission_count;

  INSERT INTO encounter (
    encounter_no,
    patient_id,
    department_id,
    doctor_id,
    registration_id,
    encounter_type,
    started_at,
    ended_at,
    status,
    note
  )
  SELECT
    CONCAT('enc_ip_', LPAD(a.admission_id, 10, '0')),
    a.patient_id,
    a.department_id,
    a.attending_doctor_id,
    NULL,
    'INPATIENT',
    a.admitted_at,
    a.discharged_at,
    CASE WHEN a.status = 'DISCHARGED' THEN 'CLOSED' ELSE 'OPEN' END,
    NULL
  FROM admission a;

  -- =========================
  -- 处方/发药
  -- =========================

  INSERT INTO prescription (
    prescription_no,
    encounter_id,
    doctor_id,
    issued_at,
    status,
    total_amount,
    note
  )
  SELECT
    CONCAT('rx_', LPAD(e.encounter_id, 10, '0')),
    e.encounter_id,
    e.doctor_id,
    DATE_ADD(e.started_at, INTERVAL 5 MINUTE),
    CASE WHEN MOD(e.encounter_id, 3) = 0 THEN 'DISPENSED' ELSE 'ISSUED' END,
    0.00,
    NULL
  FROM encounter e
  WHERE MOD(e.encounter_id, 10) < 7;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_prescription (
    prescription_id BIGINT NOT NULL,
    PRIMARY KEY (prescription_id)
  ) ENGINE=Memory;
  TRUNCATE TABLE tmp_prescription;
  INSERT INTO tmp_prescription (prescription_id)
  SELECT p.prescription_id
  FROM prescription p;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_item_seq (
    item_no INT NOT NULL,
    PRIMARY KEY (item_no)
  ) ENGINE=Memory;

  TRUNCATE TABLE tmp_item_seq;

  INSERT INTO tmp_item_seq (item_no)
  SELECT s.n
  FROM tmp_seq s
  WHERE s.n <= GREATEST(p_rx_items_max, p_lab_items_max);

  INSERT INTO prescription_item (
    prescription_id,
    drug_id,
    quantity,
    unit_price,
    amount,
    usage_instructions,
    frequency,
    days
  )
  SELECT
    p.prescription_id,
    1 + MOD(p.prescription_id * 17 + it.item_no, p_drug_count),
    1 + MOD(p.prescription_id + it.item_no, 5),
    NULL,
    0.00,
    '口服',
    'BID',
    3 + MOD(p.prescription_id, 5)
  FROM tmp_prescription p
  JOIN tmp_item_seq it ON it.item_no <= (1 + MOD(p.prescription_id, p_rx_items_max));

  INSERT INTO dispense (
    prescription_id,
    pharmacist_id,
    dispensed_at,
    status,
    note
  )
  SELECT
    p.prescription_id,
    (p_doctor_count + 1) + MOD(p.prescription_id - 1, p_pharmacist_count),
    DATE_ADD(p.issued_at, INTERVAL 30 MINUTE),
    'DISPENSED',
    NULL
  FROM prescription p
  WHERE p.status = 'DISPENSED' AND p_pharmacist_count > 0;

  -- =========================
  -- 检验：开单/明细/结果
  -- =========================

  INSERT INTO lab_order (
    lab_order_no,
    encounter_id,
    doctor_id,
    ordered_at,
    status,
    total_amount,
    note
  )
  SELECT
    CONCAT('lab_', LPAD(e.encounter_id, 10, '0')),
    e.encounter_id,
    e.doctor_id,
    DATE_ADD(e.started_at, INTERVAL 8 MINUTE),
    CASE WHEN MOD(e.encounter_id, 5) = 0 THEN 'REPORTED' ELSE 'ORDERED' END,
    0.00,
    NULL
  FROM encounter e
  WHERE MOD(e.encounter_id, 10) < 5;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_lab_order (
    lab_order_id BIGINT NOT NULL,
    PRIMARY KEY (lab_order_id)
  ) ENGINE=Memory;
  TRUNCATE TABLE tmp_lab_order;
  INSERT INTO tmp_lab_order (lab_order_id)
  SELECT lo.lab_order_id
  FROM lab_order lo;

  INSERT INTO lab_order_item (
    lab_order_id,
    lab_test_id,
    quantity,
    unit_price,
    amount
  )
  SELECT
    lo.lab_order_id,
    1 + MOD(lo.lab_order_id * 19 + it.item_no, p_lab_test_count),
    1 + MOD(lo.lab_order_id + it.item_no, 3),
    NULL,
    0.00
  FROM tmp_lab_order lo
  JOIN tmp_item_seq it ON it.item_no <= (1 + MOD(lo.lab_order_id, p_lab_items_max));

  INSERT INTO lab_result (
    lab_order_item_id,
    result_value,
    result_text,
    result_flag,
    result_at,
    technician_id,
    verified_by,
    verified_at
  )
  SELECT
    li.lab_order_item_id,
    CONCAT(ROUND(10 + MOD(li.lab_order_item_id, 200) / 10, 1)),
    NULL,
    CASE MOD(li.lab_order_item_id, 6)
      WHEN 0 THEN 'NORMAL'
      WHEN 1 THEN 'HIGH'
      WHEN 2 THEN 'LOW'
      WHEN 3 THEN 'POSITIVE'
      WHEN 4 THEN 'NEGATIVE'
      ELSE 'ABNORMAL'
    END,
    DATE_ADD(lo.ordered_at, INTERVAL 2 HOUR),
    CASE
      WHEN p_technician_count > 0 THEN (p_doctor_count + p_pharmacist_count + 1) + MOD(li.lab_order_item_id - 1, p_technician_count)
      ELSE NULL
    END,
    NULL,
    NULL
  FROM lab_order_item li
  JOIN lab_order lo ON lo.lab_order_id = li.lab_order_id
  WHERE MOD(li.lab_order_item_id, 5) <> 0;

  -- =========================
  -- 收费/发票/支付/退款（演示全链路）
  -- =========================

	  INSERT INTO charge (
	    charge_no,
	    encounter_id,
	    source_type,
	    source_id,
	    charge_item_id,
	    quantity,
	    unit_price,
	    amount,
	    charged_at,
	    status
	  )
		  SELECT
		    CONCAT('chg_reg_', LPAD(e.encounter_id, 10, '0')),
		    e.encounter_id,
		    'REGISTRATION',
		    e.registration_id,
		    v_charge_item_reg,
		    1.00,
		    NULL,
		    0.00,
		    e.started_at,
		    'UNBILLED'
		  FROM encounter e
		  WHERE e.registration_id IS NOT NULL;

	  INSERT INTO charge (
	    charge_no,
	    encounter_id,
	    source_type,
	    source_id,
	    charge_item_id,
	    quantity,
	    unit_price,
	    amount,
	    charged_at,
	    status
	  )
		  SELECT
		    CONCAT('chg_consult_', LPAD(e.encounter_id, 10, '0')),
		    e.encounter_id,
		    'MANUAL',
		    NULL,
		    v_charge_item_consult,
		    1.00,
		    NULL,
		    0.00,
		    e.started_at,
		    'UNBILLED'
		  FROM encounter e;

	  INSERT INTO charge (
	    charge_no,
	    encounter_id,
	    source_type,
	    source_id,
	    charge_item_id,
	    quantity,
	    unit_price,
	    amount,
	    charged_at,
	    status
	  )
		  SELECT
		    CONCAT('chg_rx_', LPAD(p.prescription_id, 10, '0')),
		    p.encounter_id,
		    'PRESCRIPTION',
		    p.prescription_id,
		    v_charge_item_rx,
		    1.00,
		    p.total_amount,
		    0.00,
		    p.issued_at,
		    'UNBILLED'
		  FROM prescription p
		  WHERE p.total_amount > 0;

	  INSERT INTO charge (
	    charge_no,
	    encounter_id,
	    source_type,
	    source_id,
	    charge_item_id,
	    quantity,
	    unit_price,
	    amount,
	    charged_at,
	    status
	  )
		  SELECT
		    CONCAT('chg_lab_', LPAD(lo.lab_order_id, 10, '0')),
		    lo.encounter_id,
		    'LAB',
		    lo.lab_order_id,
		    v_charge_item_lab,
		    1.00,
		    lo.total_amount,
		    0.00,
		    lo.ordered_at,
		    'UNBILLED'
		  FROM lab_order lo
		  WHERE lo.total_amount > 0;

  INSERT INTO invoice (
    invoice_no,
    patient_id,
    encounter_id,
    issued_at,
    status,
    total_amount,
    paid_amount,
    note
  )
  SELECT
    CONCAT('inv_', LPAD(e.encounter_id, 10, '0')),
    e.patient_id,
    e.encounter_id,
    DATE_ADD(e.started_at, INTERVAL 20 MINUTE),
    'OPEN',
    0.00,
    0.00,
    NULL
  FROM encounter e
  WHERE MOD(e.encounter_id, 100) < p_invoice_pct;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_invoice (
    invoice_id BIGINT NOT NULL,
    encounter_id BIGINT NOT NULL,
    PRIMARY KEY (invoice_id),
    KEY ix_tmp_invoice_encounter_id (encounter_id)
  ) ENGINE=Memory;
  TRUNCATE TABLE tmp_invoice;
  INSERT INTO tmp_invoice (invoice_id, encounter_id)
  SELECT i.invoice_id, i.encounter_id
  FROM invoice i;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_charge (
    charge_id BIGINT NOT NULL,
    encounter_id BIGINT NOT NULL,
    PRIMARY KEY (charge_id),
    KEY ix_tmp_charge_encounter_id (encounter_id)
  ) ENGINE=Memory;
  TRUNCATE TABLE tmp_charge;
  INSERT INTO tmp_charge (charge_id, encounter_id)
  SELECT c.charge_id, c.encounter_id
  FROM charge c;

  INSERT INTO invoice_line (
    invoice_id,
    charge_id
  )
  SELECT
    i.invoice_id,
    c.charge_id
  FROM tmp_invoice i
  JOIN tmp_charge c ON c.encounter_id = i.encounter_id;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_invoice_pay (
    invoice_id BIGINT NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    issued_at DATETIME(3) NOT NULL,
    PRIMARY KEY (invoice_id)
  ) ENGINE=Memory;
  TRUNCATE TABLE tmp_invoice_pay;
  INSERT INTO tmp_invoice_pay (invoice_id, total_amount, issued_at)
  SELECT i.invoice_id, i.total_amount, i.issued_at
  FROM invoice i;

  -- 全额支付：invoice_id % 100 < payment_pct
  INSERT INTO payment (
    payment_no,
    invoice_id,
    method,
    amount,
    paid_at,
    status,
    transaction_ref
  )
  SELECT
    CONCAT('pay_', LPAD(i.invoice_id, 10, '0')),
    i.invoice_id,
    CASE MOD(i.invoice_id, 4)
      WHEN 0 THEN 'WECHAT'
      WHEN 1 THEN 'ALIPAY'
      WHEN 2 THEN 'CARD'
      ELSE 'CASH'
    END,
    i.total_amount,
    DATE_ADD(i.issued_at, INTERVAL 1 DAY),
    'SUCCESS',
    NULL
  FROM tmp_invoice_pay i
  WHERE i.total_amount > 0 AND MOD(i.invoice_id, 100) < p_payment_pct;

  -- 部分支付：额外再覆盖 10%（紧随 payment_pct 之后）
  INSERT INTO payment (
    payment_no,
    invoice_id,
    method,
    amount,
    paid_at,
    status,
    transaction_ref
  )
  SELECT
    CONCAT('pay_part_', LPAD(i.invoice_id, 10, '0')),
    i.invoice_id,
    'CARD',
    GREATEST(0.01, ROUND(i.total_amount * 0.5, 2)),
    DATE_ADD(i.issued_at, INTERVAL 2 DAY),
    'SUCCESS',
    NULL
  FROM tmp_invoice_pay i
  WHERE i.total_amount > 0
    AND MOD(i.invoice_id, 100) >= p_payment_pct
    AND MOD(i.invoice_id, 100) < LEAST(p_payment_pct + 10, 100);

  INSERT INTO refund (
    refund_no,
    payment_id,
    amount,
    refunded_at,
    reason,
    status
  )
  SELECT
    CONCAT('refund_', LPAD(p.payment_id, 10, '0')),
    p.payment_id,
    LEAST(ROUND(p.amount * 0.10, 2), p.amount - 0.01),
    DATE_ADD(p.paid_at, INTERVAL 1 DAY),
    '测试退款',
    'SUCCESS'
  FROM payment p
  WHERE p.amount > 0.02 AND MOD(p.payment_id, 100) < p_refund_pct;

  DROP TEMPORARY TABLE IF EXISTS tmp_reg_seq;
  DROP TEMPORARY TABLE IF EXISTS tmp_item_seq;
  DROP TEMPORARY TABLE IF EXISTS tmp_prescription;
  DROP TEMPORARY TABLE IF EXISTS tmp_lab_order;
  DROP TEMPORARY TABLE IF EXISTS tmp_slot;
  DROP TEMPORARY TABLE IF EXISTS tmp_invoice;
  DROP TEMPORARY TABLE IF EXISTS tmp_invoice_pay;
  DROP TEMPORARY TABLE IF EXISTS tmp_charge;
  DROP TEMPORARY TABLE IF EXISTS tmp_seq;
END$$

DELIMITER ;
