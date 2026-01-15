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
  KEY ix_department_name (department_name),
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
  KEY ix_staff_name (staff_name),
  KEY ix_staff_phone (phone)
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

