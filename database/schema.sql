-- 医院管理系统（MySQL 9.x）- 数据库结构设计
-- 建议执行顺序：schema.sql -> triggers.sql -> security.sql

CREATE DATABASE IF NOT EXISTS hospital_test
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE hospital_test;

SET sql_safe_updates = 0;
SET time_zone = '+00:00';

-- =========================
-- 组织与人员
-- =========================

CREATE TABLE IF NOT EXISTS department (
  department_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '部门主键ID',
  department_code VARCHAR(32) NOT NULL COMMENT '部门编码',
  department_name VARCHAR(100) NOT NULL COMMENT '部门名称',
  parent_department_id BIGINT UNSIGNED NULL COMMENT '上级部门ID（自关联）',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (department_id),
  UNIQUE KEY uq_department_code (department_code),
  KEY ix_department_parent (parent_department_id),
  CONSTRAINT fk_department_parent
    FOREIGN KEY (parent_department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='部门/科室表';

CREATE TABLE IF NOT EXISTS staff (
  staff_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '员工主键ID',
  staff_no VARCHAR(32) NOT NULL COMMENT '员工工号',
  staff_name VARCHAR(100) NOT NULL COMMENT '员工姓名',
  gender ENUM('M','F','U') NOT NULL DEFAULT 'U' COMMENT '性别（M=男，F=女，U=未知）',
  phone VARCHAR(32) NULL COMMENT '联系电话',
  email VARCHAR(200) NULL COMMENT '邮箱',
  id_card_no VARCHAR(32) NULL COMMENT '身份证号',
  title VARCHAR(50) NULL COMMENT '职称/岗位',
  hire_date DATE NULL COMMENT '入职日期',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否在职/启用（1=是，0=否）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (staff_id),
  UNIQUE KEY uq_staff_no (staff_no),
  UNIQUE KEY uq_staff_id_card (id_card_no),
  KEY ix_staff_name (staff_name)
) ENGINE=InnoDB COMMENT='员工/医护人员表';

CREATE TABLE IF NOT EXISTS staff_department (
  staff_department_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '员工-部门关联主键ID',
  staff_id BIGINT UNSIGNED NOT NULL COMMENT '员工ID',
  department_id BIGINT UNSIGNED NOT NULL COMMENT '部门ID',
  is_primary TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否主科室（1=是，0=否）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (staff_department_id),
  UNIQUE KEY uq_staff_dept (staff_id, department_id),
  KEY ix_staff_dept_dept (department_id),
  CONSTRAINT fk_staff_department_staff
    FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_staff_department_department
    FOREIGN KEY (department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='员工与部门多对多关系表';

-- =========================
-- 患者与账号
-- =========================

CREATE TABLE IF NOT EXISTS patient (
  patient_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '患者主键ID',
  patient_no VARCHAR(32) NOT NULL COMMENT '患者编号/病案号',
  patient_name VARCHAR(100) NOT NULL COMMENT '患者姓名',
  gender ENUM('M','F','U') NOT NULL DEFAULT 'U' COMMENT '性别（M=男，F=女，U=未知）',
  birth_date DATE NULL COMMENT '出生日期',
  id_card_no VARCHAR(32) NULL COMMENT '身份证号',
  phone VARCHAR(32) NULL COMMENT '联系电话',
  address VARCHAR(300) NULL COMMENT '联系地址',
  emergency_contact_name VARCHAR(100) NULL COMMENT '紧急联系人姓名',
  emergency_contact_phone VARCHAR(32) NULL COMMENT '紧急联系人电话',
  blood_type ENUM('A','B','AB','O','U') NOT NULL DEFAULT 'U' COMMENT '血型（A/B/AB/O/U=未知）',
  allergy_history VARCHAR(500) NULL COMMENT '过敏史',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否有效/启用（1=是，0=否）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (patient_id),
  UNIQUE KEY uq_patient_no (patient_no),
  UNIQUE KEY uq_patient_id_card (id_card_no),
  KEY ix_patient_name (patient_name),
  KEY ix_patient_phone (phone)
) ENGINE=InnoDB COMMENT='患者信息表';

CREATE TABLE IF NOT EXISTS user_account (
  user_account_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '账号主键ID',
  username VARCHAR(128) NOT NULL COMMENT '登录用户名',
  password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
  staff_id BIGINT UNSIGNED NULL COMMENT '绑定员工ID（员工账号）',
  patient_id BIGINT UNSIGNED NULL COMMENT '绑定患者ID（患者账号）',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  last_login_at DATETIME(3) NULL COMMENT '最后登录时间',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (user_account_id),
  UNIQUE KEY uq_user_username (username),
  KEY ix_user_staff (staff_id),
  KEY ix_user_patient (patient_id),
  CONSTRAINT fk_user_staff
    FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_user_patient
    FOREIGN KEY (patient_id) REFERENCES patient (patient_id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT ck_user_owner
    CHECK ((staff_id IS NULL) <> (patient_id IS NULL))
) ENGINE=InnoDB COMMENT='用户账号表（员工/患者二选一绑定）';

-- =========================
-- 门诊：排班/挂号/就诊/诊断
-- =========================

CREATE TABLE IF NOT EXISTS doctor_schedule (
  schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '医生排班主键ID',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '医生ID（staff.staff_id）',
  department_id BIGINT UNSIGNED NOT NULL COMMENT '科室ID',
  schedule_date DATE NOT NULL COMMENT '排班日期',
  start_time TIME NOT NULL COMMENT '开始时间',
  end_time TIME NOT NULL COMMENT '结束时间',
  quota INT UNSIGNED NOT NULL COMMENT '号源配额/可挂号数量',
  registration_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '挂号费',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (schedule_id),
  UNIQUE KEY uq_schedule_unique (doctor_id, schedule_date, start_time, end_time),
  KEY ix_schedule_dept_date (department_id, schedule_date),
  CONSTRAINT fk_schedule_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_schedule_dept
    FOREIGN KEY (department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_schedule_time
    CHECK (end_time > start_time)
) ENGINE=InnoDB COMMENT='医生排班表';

CREATE TABLE IF NOT EXISTS registration (
  registration_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '挂号记录主键ID',
  registration_no VARCHAR(40) NOT NULL COMMENT '挂号单号',
  patient_id BIGINT UNSIGNED NOT NULL COMMENT '患者ID',
  schedule_id BIGINT UNSIGNED NOT NULL COMMENT '排班ID',
  registered_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '挂号时间',
  status ENUM('CONFIRMED','CANCELLED','COMPLETED') NOT NULL DEFAULT 'CONFIRMED' COMMENT '挂号状态（CONFIRMED=已确认，CANCELLED=已取消，COMPLETED=已完成）',
  chief_complaint VARCHAR(500) NULL COMMENT '主诉',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (registration_id),
  UNIQUE KEY uq_registration_no (registration_no),
  UNIQUE KEY uq_registration_unique (patient_id, schedule_id),
  KEY ix_registration_patient_time (patient_id, registered_at),
  KEY ix_registration_schedule (schedule_id),
  CONSTRAINT fk_registration_patient
    FOREIGN KEY (patient_id) REFERENCES patient (patient_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_registration_schedule
    FOREIGN KEY (schedule_id) REFERENCES doctor_schedule (schedule_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='门诊挂号表';

CREATE TABLE IF NOT EXISTS encounter (
  encounter_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '就诊主键ID',
  encounter_no VARCHAR(40) NOT NULL COMMENT '就诊号',
  patient_id BIGINT UNSIGNED NOT NULL COMMENT '患者ID',
  department_id BIGINT UNSIGNED NOT NULL COMMENT '就诊科室ID',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '接诊医生ID',
  registration_id BIGINT UNSIGNED NULL COMMENT '关联挂号ID（门诊可用）',
  encounter_type ENUM('OUTPATIENT','INPATIENT') NOT NULL DEFAULT 'OUTPATIENT' COMMENT '就诊类型（OUTPATIENT=门诊，INPATIENT=住院）',
  started_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '开始时间',
  ended_at DATETIME(3) NULL COMMENT '结束时间',
  status ENUM('OPEN','CLOSED','CANCELLED') NOT NULL DEFAULT 'OPEN' COMMENT '就诊状态（OPEN=进行中，CLOSED=已结束，CANCELLED=已取消）',
  note VARCHAR(1000) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (encounter_id),
  UNIQUE KEY uq_encounter_no (encounter_no),
  UNIQUE KEY uq_encounter_registration (registration_id),
  KEY ix_encounter_patient_time (patient_id, started_at),
  KEY ix_encounter_doctor_time (doctor_id, started_at),
  CONSTRAINT fk_encounter_patient
    FOREIGN KEY (patient_id) REFERENCES patient (patient_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_encounter_dept
    FOREIGN KEY (department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_encounter_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_encounter_registration
    FOREIGN KEY (registration_id) REFERENCES registration (registration_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT ck_encounter_time
    CHECK (ended_at IS NULL OR ended_at >= started_at)
) ENGINE=InnoDB COMMENT='就诊记录表（门诊/住院统一入口）';

CREATE TABLE IF NOT EXISTS diagnosis (
  diagnosis_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '诊断主键ID',
  encounter_id BIGINT UNSIGNED NOT NULL COMMENT '就诊ID',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '诊断医生ID',
  diagnosis_code VARCHAR(32) NULL COMMENT '诊断编码（如ICD，可选）',
  diagnosis_name VARCHAR(200) NOT NULL COMMENT '诊断名称',
  diagnosis_type ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'SECONDARY' COMMENT '诊断类型（PRIMARY=主诊断，SECONDARY=次诊断）',
  diagnosed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '诊断时间',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (diagnosis_id),
  KEY ix_diagnosis_encounter (encounter_id),
  KEY ix_diagnosis_name (diagnosis_name),
  CONSTRAINT fk_diagnosis_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_diagnosis_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='就诊诊断表';

-- =========================
-- 住院：病区/床位/入院/床位分配
-- =========================

CREATE TABLE IF NOT EXISTS ward (
  ward_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '病区主键ID',
  ward_code VARCHAR(32) NOT NULL COMMENT '病区编码',
  ward_name VARCHAR(100) NOT NULL COMMENT '病区名称',
  department_id BIGINT UNSIGNED NOT NULL COMMENT '所属科室ID',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (ward_id),
  UNIQUE KEY uq_ward_code (ward_code),
  KEY ix_ward_dept (department_id),
  CONSTRAINT fk_ward_dept
    FOREIGN KEY (department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='住院病区表';

CREATE TABLE IF NOT EXISTS bed (
  bed_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '床位主键ID',
  ward_id BIGINT UNSIGNED NOT NULL COMMENT '所属病区ID',
  bed_no VARCHAR(32) NOT NULL COMMENT '床位号',
  status ENUM('AVAILABLE','MAINTENANCE','DISABLED') NOT NULL DEFAULT 'AVAILABLE' COMMENT '床位状态（AVAILABLE=可用，MAINTENANCE=维护中，DISABLED=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (bed_id),
  UNIQUE KEY uq_bed_unique (ward_id, bed_no),
  KEY ix_bed_ward (ward_id),
  CONSTRAINT fk_bed_ward
    FOREIGN KEY (ward_id) REFERENCES ward (ward_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='床位表';

CREATE TABLE IF NOT EXISTS admission (
  admission_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '入院记录主键ID',
  admission_no VARCHAR(40) NOT NULL COMMENT '住院号/入院号',
  patient_id BIGINT UNSIGNED NOT NULL COMMENT '患者ID',
  department_id BIGINT UNSIGNED NOT NULL COMMENT '住院科室ID',
  attending_doctor_id BIGINT UNSIGNED NOT NULL COMMENT '主治医生ID',
  admitted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '入院时间',
  discharged_at DATETIME(3) NULL COMMENT '出院时间',
  status ENUM('ADMITTED','DISCHARGED','CANCELLED') NOT NULL DEFAULT 'ADMITTED' COMMENT '住院状态（ADMITTED=在院，DISCHARGED=出院，CANCELLED=取消）',
  note VARCHAR(1000) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (admission_id),
  UNIQUE KEY uq_admission_no (admission_no),
  KEY ix_admission_patient_time (patient_id, admitted_at),
  CONSTRAINT fk_admission_patient
    FOREIGN KEY (patient_id) REFERENCES patient (patient_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_admission_dept
    FOREIGN KEY (department_id) REFERENCES department (department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_admission_doctor
    FOREIGN KEY (attending_doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_admission_time
    CHECK (discharged_at IS NULL OR discharged_at >= admitted_at)
) ENGINE=InnoDB COMMENT='入院记录表';

CREATE TABLE IF NOT EXISTS bed_assignment (
  bed_assignment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '床位分配主键ID',
  admission_id BIGINT UNSIGNED NOT NULL COMMENT '入院记录ID',
  bed_id BIGINT UNSIGNED NOT NULL COMMENT '床位ID',
  start_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '分配开始时间',
  end_at DATETIME(3) NULL COMMENT '分配结束时间（NULL=仍占用）',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (bed_assignment_id),
  KEY ix_bed_assignment_bed_time (bed_id, start_at),
  KEY ix_bed_assignment_admission (admission_id),
  CONSTRAINT fk_bed_assignment_admission
    FOREIGN KEY (admission_id) REFERENCES admission (admission_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_bed_assignment_bed
    FOREIGN KEY (bed_id) REFERENCES bed (bed_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_bed_assignment_time
    CHECK (end_at IS NULL OR end_at >= start_at)
) ENGINE=InnoDB COMMENT='床位分配/占用时间段表';

-- =========================
-- 药品与处方
-- =========================

CREATE TABLE IF NOT EXISTS drug (
  drug_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '药品主键ID',
  drug_code VARCHAR(32) NOT NULL COMMENT '药品编码',
  drug_name VARCHAR(200) NOT NULL COMMENT '药品名称',
  specification VARCHAR(200) NULL COMMENT '规格',
  dosage_form VARCHAR(50) NULL COMMENT '剂型',
  unit VARCHAR(20) NOT NULL COMMENT '计量单位',
  manufacturer VARCHAR(200) NULL COMMENT '生产厂家',
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (drug_id),
  UNIQUE KEY uq_drug_code (drug_code),
  KEY ix_drug_name (drug_name),
  CONSTRAINT ck_drug_price
    CHECK (unit_price >= 0)
) ENGINE=InnoDB COMMENT='药品目录表';

CREATE TABLE IF NOT EXISTS prescription (
  prescription_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '处方主键ID',
  prescription_no VARCHAR(40) NOT NULL COMMENT '处方号',
  encounter_id BIGINT UNSIGNED NOT NULL COMMENT '就诊ID',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '开方医生ID',
  issued_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '开具时间',
  status ENUM('DRAFT','ISSUED','DISPENSED','CANCELLED') NOT NULL DEFAULT 'ISSUED' COMMENT '处方状态（DRAFT=草稿，ISSUED=已开立，DISPENSED=已发药，CANCELLED=已作废）',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '处方总金额',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (prescription_id),
  UNIQUE KEY uq_prescription_no (prescription_no),
  KEY ix_prescription_encounter (encounter_id),
  CONSTRAINT fk_prescription_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_prescription_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_prescription_total
    CHECK (total_amount >= 0)
) ENGINE=InnoDB COMMENT='处方表';

CREATE TABLE IF NOT EXISTS prescription_item (
  prescription_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '处方明细主键ID',
  prescription_id BIGINT UNSIGNED NOT NULL COMMENT '处方ID',
  drug_id BIGINT UNSIGNED NOT NULL COMMENT '药品ID',
  quantity DECIMAL(12,2) NOT NULL COMMENT '数量',
  unit_price DECIMAL(10,2) NULL COMMENT '单价（为空时可由触发器从药品目录带出）',
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '明细金额（quantity * unit_price）',
  usage_instructions VARCHAR(200) NULL COMMENT '用法说明',
  frequency VARCHAR(50) NULL COMMENT '频次',
  days INT UNSIGNED NULL COMMENT '用药天数',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (prescription_item_id),
  KEY ix_prescription_item_prescription (prescription_id),
  KEY ix_prescription_item_drug (drug_id),
  CONSTRAINT fk_prescription_item_prescription
    FOREIGN KEY (prescription_id) REFERENCES prescription (prescription_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_prescription_item_drug
    FOREIGN KEY (drug_id) REFERENCES drug (drug_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_prescription_item_qty
    CHECK (quantity > 0),
  CONSTRAINT ck_prescription_item_amount
    CHECK (amount >= 0)
) ENGINE=InnoDB COMMENT='处方明细表';

CREATE TABLE IF NOT EXISTS dispense (
  dispense_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '发药记录主键ID',
  prescription_id BIGINT UNSIGNED NOT NULL COMMENT '处方ID',
  pharmacist_id BIGINT UNSIGNED NOT NULL COMMENT '发药药师ID',
  dispensed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发药时间',
  status ENUM('DISPENSED','CANCELLED') NOT NULL DEFAULT 'DISPENSED' COMMENT '发药状态（DISPENSED=已发药，CANCELLED=已取消）',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (dispense_id),
  UNIQUE KEY uq_dispense_prescription (prescription_id),
  CONSTRAINT fk_dispense_prescription
    FOREIGN KEY (prescription_id) REFERENCES prescription (prescription_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_dispense_pharmacist
    FOREIGN KEY (pharmacist_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='处方发药记录表';

-- =========================
-- 检验检查
-- =========================

CREATE TABLE IF NOT EXISTS lab_test (
  lab_test_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '检验项目主键ID',
  test_code VARCHAR(32) NOT NULL COMMENT '检验项目编码',
  test_name VARCHAR(200) NOT NULL COMMENT '检验项目名称',
  category VARCHAR(100) NULL COMMENT '项目分类',
  specimen VARCHAR(100) NULL COMMENT '标本类型',
  unit VARCHAR(50) NULL COMMENT '结果单位',
  reference_range VARCHAR(200) NULL COMMENT '参考范围',
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (lab_test_id),
  UNIQUE KEY uq_lab_test_code (test_code),
  KEY ix_lab_test_name (test_name),
  CONSTRAINT ck_lab_test_price
    CHECK (unit_price >= 0)
) ENGINE=InnoDB COMMENT='检验项目目录表';

CREATE TABLE IF NOT EXISTS lab_order (
  lab_order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '检验开单主键ID',
  lab_order_no VARCHAR(40) NOT NULL COMMENT '检验单号',
  encounter_id BIGINT UNSIGNED NOT NULL COMMENT '就诊ID',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '开单医生ID',
  ordered_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '开单时间',
  status ENUM('ORDERED','COLLECTED','REPORTED','CANCELLED') NOT NULL DEFAULT 'ORDERED' COMMENT '检验单状态（ORDERED=已开单，COLLECTED=已采样，REPORTED=已报告，CANCELLED=已取消）',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '检验单总金额',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (lab_order_id),
  UNIQUE KEY uq_lab_order_no (lab_order_no),
  KEY ix_lab_order_encounter (encounter_id),
  CONSTRAINT fk_lab_order_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_lab_order_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_lab_order_total
    CHECK (total_amount >= 0)
) ENGINE=InnoDB COMMENT='检验开单表';

CREATE TABLE IF NOT EXISTS lab_order_item (
  lab_order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '检验明细主键ID',
  lab_order_id BIGINT UNSIGNED NOT NULL COMMENT '检验单ID',
  lab_test_id BIGINT UNSIGNED NOT NULL COMMENT '检验项目ID',
  quantity INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '数量',
  unit_price DECIMAL(10,2) NULL COMMENT '单价（为空时可由触发器从检验项目目录带出）',
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '明细金额（quantity * unit_price）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (lab_order_item_id),
  KEY ix_lab_order_item_order (lab_order_id),
  KEY ix_lab_order_item_test (lab_test_id),
  CONSTRAINT fk_lab_order_item_order
    FOREIGN KEY (lab_order_id) REFERENCES lab_order (lab_order_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_lab_order_item_test
    FOREIGN KEY (lab_test_id) REFERENCES lab_test (lab_test_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_lab_order_item_qty
    CHECK (quantity > 0),
  CONSTRAINT ck_lab_order_item_amount
    CHECK (amount >= 0)
) ENGINE=InnoDB COMMENT='检验开单明细表';

CREATE TABLE IF NOT EXISTS lab_result (
  lab_result_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '检验结果主键ID',
  lab_order_item_id BIGINT UNSIGNED NOT NULL COMMENT '检验明细ID',
  result_value VARCHAR(200) NULL COMMENT '结果值（结构化）',
  result_text VARCHAR(1000) NULL COMMENT '结果描述（文本）',
  result_flag ENUM('NORMAL','HIGH','LOW','POSITIVE','NEGATIVE','ABNORMAL','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN' COMMENT '结果标志（NORMAL/HIGH/LOW/POSITIVE/NEGATIVE/ABNORMAL/UNKNOWN）',
  result_at DATETIME(3) NULL COMMENT '出结果时间',
  technician_id BIGINT UNSIGNED NULL COMMENT '检验技师ID',
  verified_by BIGINT UNSIGNED NULL COMMENT '审核人ID',
  verified_at DATETIME(3) NULL COMMENT '审核时间',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (lab_result_id),
  UNIQUE KEY uq_lab_result_item (lab_order_item_id),
  KEY ix_lab_result_tech (technician_id),
  CONSTRAINT fk_lab_result_item
    FOREIGN KEY (lab_order_item_id) REFERENCES lab_order_item (lab_order_item_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_lab_result_technician
    FOREIGN KEY (technician_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_lab_result_verified_by
    FOREIGN KEY (verified_by) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='检验结果表';

-- =========================
-- 收费与结算：收费项目/费用/发票/支付/退款
-- =========================

CREATE TABLE IF NOT EXISTS charge_catalog (
  charge_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '收费项目主键ID',
  item_code VARCHAR(32) NOT NULL COMMENT '收费项目编码',
  item_name VARCHAR(200) NOT NULL COMMENT '收费项目名称',
  category VARCHAR(100) NULL COMMENT '项目类别',
  unit VARCHAR(20) NULL COMMENT '计价单位',
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用（1=启用，0=停用）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (charge_item_id),
  UNIQUE KEY uq_charge_item_code (item_code),
  KEY ix_charge_item_name (item_name),
  CONSTRAINT ck_charge_catalog_price
    CHECK (unit_price >= 0)
) ENGINE=InnoDB COMMENT='收费项目目录表';

CREATE TABLE IF NOT EXISTS charge (
  charge_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '费用记录主键ID',
  charge_no VARCHAR(40) NOT NULL COMMENT '费用单号',
  encounter_id BIGINT UNSIGNED NOT NULL COMMENT '就诊ID',
  source_type ENUM('REGISTRATION','PRESCRIPTION','LAB','MANUAL') NOT NULL DEFAULT 'MANUAL' COMMENT '来源类型（REGISTRATION/处方/检验/手工）',
  source_id BIGINT UNSIGNED NULL COMMENT '来源记录ID（与 source_type 配套）',
  charge_item_id BIGINT UNSIGNED NOT NULL COMMENT '收费项目ID',
  quantity DECIMAL(12,2) NOT NULL DEFAULT 1.00 COMMENT '数量',
  unit_price DECIMAL(10,2) NULL COMMENT '单价（为空时可由触发器从收费项目目录带出）',
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '金额（quantity * unit_price）',
  charged_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '计费时间',
  status ENUM('UNBILLED','BILLED','CANCELLED') NOT NULL DEFAULT 'UNBILLED' COMMENT '费用状态（UNBILLED=未开票，BILLED=已开票，CANCELLED=已取消）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (charge_id),
  UNIQUE KEY uq_charge_no (charge_no),
  KEY ix_charge_encounter_time (encounter_id, charged_at),
  KEY ix_charge_item (charge_item_id),
  CONSTRAINT fk_charge_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_charge_item
    FOREIGN KEY (charge_item_id) REFERENCES charge_catalog (charge_item_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_charge_qty
    CHECK (quantity > 0),
  CONSTRAINT ck_charge_amount
    CHECK (amount >= 0)
) ENGINE=InnoDB COMMENT='费用明细表';

CREATE TABLE IF NOT EXISTS invoice (
  invoice_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '发票主键ID',
  invoice_no VARCHAR(40) NOT NULL COMMENT '发票号',
  patient_id BIGINT UNSIGNED NOT NULL COMMENT '患者ID',
  encounter_id BIGINT UNSIGNED NULL COMMENT '就诊ID（可为空）',
  issued_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '开票时间',
  status ENUM('OPEN','PARTIALLY_PAID','PAID','VOID') NOT NULL DEFAULT 'OPEN' COMMENT '发票状态（OPEN=未结清，PARTIALLY_PAID=部分已付，PAID=已付清，VOID=作废）',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '发票总金额',
  paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '已付金额（支付-退款）',
  note VARCHAR(500) NULL COMMENT '备注',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (invoice_id),
  UNIQUE KEY uq_invoice_no (invoice_no),
  KEY ix_invoice_patient_time (patient_id, issued_at),
  KEY ix_invoice_encounter (encounter_id),
  CONSTRAINT fk_invoice_patient
    FOREIGN KEY (patient_id) REFERENCES patient (patient_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT ck_invoice_total
    CHECK (total_amount >= 0),
  CONSTRAINT ck_invoice_paid
    CHECK (paid_amount >= 0)
) ENGINE=InnoDB COMMENT='发票表';

CREATE TABLE IF NOT EXISTS invoice_line (
  invoice_line_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '发票明细主键ID',
  invoice_id BIGINT UNSIGNED NOT NULL COMMENT '发票ID',
  charge_id BIGINT UNSIGNED NOT NULL COMMENT '费用ID',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (invoice_line_id),
  UNIQUE KEY uq_invoice_line_unique (invoice_id, charge_id),
  KEY ix_invoice_line_charge (charge_id),
  CONSTRAINT fk_invoice_line_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoice (invoice_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_line_charge
    FOREIGN KEY (charge_id) REFERENCES charge (charge_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='发票与费用关联明细表';

CREATE TABLE IF NOT EXISTS payment (
  payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '支付记录主键ID',
  payment_no VARCHAR(40) NOT NULL COMMENT '支付单号',
  invoice_id BIGINT UNSIGNED NOT NULL COMMENT '发票ID',
  method ENUM('CASH','CARD','WECHAT','ALIPAY','TRANSFER','OTHER') NOT NULL DEFAULT 'CASH' COMMENT '支付方式（现金/银行卡/微信/支付宝/转账/其他）',
  amount DECIMAL(12,2) NOT NULL COMMENT '支付金额',
  paid_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '支付时间',
  status ENUM('SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'SUCCESS' COMMENT '支付状态（SUCCESS=成功，FAILED=失败，CANCELLED=取消）',
  transaction_ref VARCHAR(100) NULL COMMENT '第三方交易流水号/参考号',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (payment_id),
  UNIQUE KEY uq_payment_no (payment_no),
  KEY ix_payment_invoice_time (invoice_id, paid_at),
  CONSTRAINT fk_payment_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoice (invoice_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_payment_amount
    CHECK (amount > 0)
) ENGINE=InnoDB COMMENT='支付记录表';

CREATE TABLE IF NOT EXISTS refund (
  refund_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '退款记录主键ID',
  refund_no VARCHAR(40) NOT NULL COMMENT '退款单号',
  payment_id BIGINT UNSIGNED NOT NULL COMMENT '原支付记录ID',
  amount DECIMAL(12,2) NOT NULL COMMENT '退款金额',
  refunded_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '退款时间',
  reason VARCHAR(300) NULL COMMENT '退款原因',
  status ENUM('SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'SUCCESS' COMMENT '退款状态（SUCCESS=成功，FAILED=失败，CANCELLED=取消）',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  created_by VARCHAR(128) NULL COMMENT '创建者（数据库用户）',
  updated_by VARCHAR(128) NULL COMMENT '更新者（数据库用户）',
  PRIMARY KEY (refund_id),
  UNIQUE KEY uq_refund_no (refund_no),
  KEY ix_refund_payment_time (payment_id, refunded_at),
  CONSTRAINT fk_refund_payment
    FOREIGN KEY (payment_id) REFERENCES payment (payment_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_refund_amount
    CHECK (amount > 0)
) ENGINE=InnoDB COMMENT='退款记录表';
