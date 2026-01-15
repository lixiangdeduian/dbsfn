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
  KEY ix_schedule_date (schedule_date),
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
  KEY ix_registration_status (status),
  KEY ix_registration_time (registered_at),
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
  KEY ix_encounter_dept (department_id),
  KEY ix_encounter_status (status),
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
  KEY ix_diagnosis_doctor (doctor_id),
  CONSTRAINT fk_diagnosis_encounter
    FOREIGN KEY (encounter_id) REFERENCES encounter (encounter_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_diagnosis_doctor
    FOREIGN KEY (doctor_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='就诊诊断表';

