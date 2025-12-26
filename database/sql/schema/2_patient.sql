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

