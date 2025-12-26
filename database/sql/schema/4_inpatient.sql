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

