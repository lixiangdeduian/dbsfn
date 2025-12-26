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

