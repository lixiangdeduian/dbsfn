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
  KEY ix_prescription_doctor (doctor_id),
  KEY ix_prescription_status (status),
  KEY ix_prescription_issued (issued_at),
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
  KEY ix_dispense_pharmacist (pharmacist_id),
  CONSTRAINT fk_dispense_prescription
    FOREIGN KEY (prescription_id) REFERENCES prescription (prescription_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_dispense_pharmacist
    FOREIGN KEY (pharmacist_id) REFERENCES staff (staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='处方发药记录表';

