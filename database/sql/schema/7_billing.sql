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
  KEY ix_charge_source (source_type, source_id),
  KEY ix_charge_status (status),
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
  KEY ix_refund_status (status),
  CONSTRAINT fk_refund_payment
    FOREIGN KEY (payment_id) REFERENCES payment (payment_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_refund_amount
    CHECK (amount > 0)
) ENGINE=InnoDB COMMENT='退款记录表';
