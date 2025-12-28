# 系统功能完整说明

## 🎯 系统概述

本系统是一个完整的**基于角色权限控制的医院管理系统**，实现了门诊、住院、药房、检验、收费等全流程管理。

### 核心特性

- ✅ **8个角色**，细粒度权限控制
- ✅ **数据库视图安全**，行级和列级数据隔离
- ✅ **存储过程**，包含游标的复杂业务逻辑
- ✅ **触发器**，自动维护数据一致性
- ✅ **动态菜单**，根据角色显示不同功能
- ✅ **美观UI**，基于Ant Design 5

---

## 👥 角色权限体系

### 1. 超级管理员（admin）

**权限范围：** 全库权限，可以访问所有功能

**可见菜单（9个）：**
- 仪表盘
- 患者管理
- 员工管理
- 科室管理
- 排班管理
- 挂号管理
- 就诊管理
- 收费管理
- 统计报表

**主要功能：**
- 系统配置
- 用户权限管理
- 数据查询和修改
- 所有存储过程调用
- 统计分析

---

### 2. 医生（doctor）

**权限范围：** 患者诊疗、处方开立、检验开单

**可见菜单（5个）：**
- 仪表盘
- 患者管理（只读）
- 排班管理（只读自己的排班）
- 挂号管理（只读）
- 就诊管理（可读写）

**数据库视图：**
- `v_doctor_my_schedule` - 我的排班
- `v_doctor_my_registrations` - 我的挂号
- `v_doctor_my_encounters` - 我的就诊
- `v_doctor_my_prescriptions_detail` - 我的处方明细
- `v_doctor_my_lab_results` - 我的检验结果

**主要功能：**
- 查看自己的排班和挂号
- 创建和管理就诊记录
- 开立处方
- 开立检验单
- 查看诊断历史

**只读字段：**
- 患者身份证号
- 发票信息
- 支付信息

---

### 3. 护士（nurse）

**权限范围：** 住院管理、床位分配

**可见菜单（4个）：**
- 仪表盘
- 患者管理（只读）
- 就诊管理（只读）
- 住院管理（可读写）

**数据库视图：**
- `v_nurse_my_inpatients` - 我负责的住院患者
- `v_bed_occupancy` - 床位占用情况
- `v_inpatient_current` - 当前住院患者

**主要功能：**
- 办理入院（调用存储过程，使用游标自动分配床位）
- 床位管理
- 转床
- 办理出院
- 住院患者护理记录

**只读字段：**
- 发票信息
- 支付信息
- 处方信息

**可调用的存储过程：**
- `sp_inpatient_admit` - 办理入院（含游标）
- `sp_bed_assignment_transfer` - 床位转移
- `sp_inpatient_discharge` - 办理出院

---

### 4. 药剂师（pharmacist）

**权限范围：** 药品管理、处方调剂

**可见菜单（3个）：**
- 仪表盘
- 药房管理（可读写）
- 处方管理（只读）

**数据库视图：**
- `v_pharmacy_dispense_queue` - 待发药队列
- `v_pharmacy_dispense_detail` - 发药记录详情
- `v_drug_catalog_active` - 药品目录

**主要功能：**
- 查看待发药处方队列
- 发药（调用存储过程）
- 药品库存管理
- 发药历史查询

**只读字段：**
- 患者身份证号
- 发票信息
- 支付信息

**可调用的存储过程：**
- `sp_dispense_create` - 发药
- `sp_dispense_prescription` - 发药（支持指定时间）
- `sp_prescription_bill_sync` - 同步处方费用

---

### 5. 检验技师（lab_tech）

**权限范围：** 检验项目管理、结果录入

**可见菜单（3个）：**
- 仪表盘
- 检验管理（可读写）
- 检验结果（可读写）

**数据库视图：**
- `v_lab_worklist` - 检验工作台
- `v_lab_my_items` - 我负责的检验项目
- `v_lab_test_catalog_active` - 检验项目目录

**主要功能：**
- 查看检验工作台
- 录入检验结果（调用存储过程）
- 审核检验结果
- 标记采样状态

**只读字段：**
- 患者身份证号
- 发票信息
- 支付信息

**可调用的存储过程：**
- `sp_lab_order_prepare_results` - 准备结果占位（使用游标）
- `sp_lab_result_upsert` - 录入或更新结果
- `sp_lab_result_verify` - 审核结果
- `sp_lab_order_mark_collected` - 标记已采样

---

### 6. 收费员（cashier）

**权限范围：** 收费开票、支付管理

**可见菜单（4个）：**
- 仪表盘
- 收费管理（可读写）
- 支付管理（可读写）
- 统计报表（只读）

**数据库视图：**
- `v_cashier_unbilled_charges` - 未开票费用
- `v_invoice_summary` - 发票汇总
- `v_invoice_detail` - 发票明细
- `v_payment_refund_detail` - 支付退款详情

**主要功能：**
- 查看未开票费用
- 创建发票（调用存储过程，使用游标）
- 处理支付
- 处理退款
- 发票作废
- 收入统计

**只读字段：**
- 诊断信息
- 处方信息

**可调用的存储过程：**
- `sp_invoice_create_for_encounter` - 创建发票（使用游标）
- `sp_invoice_attach_unbilled_charges` - 追加费用（使用游标）
- `sp_invoice_void` - 作废发票
- `sp_payment_create` - 创建支付
- `sp_refund_create` - 创建退款

---

### 7. 前台接待（reception）

**权限范围：** 患者登记、挂号管理

**可见菜单（4个）：**
- 仪表盘
- 患者管理（可读写）
- 排班管理（只读）
- 挂号管理（可读写）

**数据库视图：**
- `v_patient_reception` - 接待用患者视图
- `v_schedule_public` - 排班公开信息
- `v_registration_detail` - 挂号详情

**主要功能：**
- 患者信息登记（调用存储过程）
- 患者信息维护
- 查看医生排班
- 预约挂号（调用存储过程）

**只读字段：**
- 过敏史
- 诊断信息
- 发票信息
- 支付信息

**可调用的存储过程：**
- `sp_patient_create` - 创建患者
- `sp_patient_update_contact` - 更新联系方式
- `sp_outpatient_register` - 门诊挂号

---

### 8. 患者（patient）

**权限范围：** 查看自己的信息（只读）

**可见菜单（3个）：**
- 仪表盘
- 我的信息（只读）
- 我的就诊记录（只读）

**数据库视图：**
- `v_current_patient` - 当前患者信息
- `v_patient_my_encounters` - 我的就诊记录
- `v_patient_my_prescriptions` - 我的处方
- `v_patient_my_lab_results` - 我的检验结果
- `v_patient_my_invoices` - 我的账单

**主要功能：**
- 查看个人基本信息
- 查看就诊历史
- 查看处方记录
- 查看检验结果
- 查看费用账单

**所有字段只读**

---

## 🗄️ 数据库设计

### 表结构（共30+张表）

#### 基础数据表
- `department` - 科室
- `staff` - 员工
- `staff_department` - 员工科室关系
- `user_account` - 用户账号
- `patient` - 患者

#### 门诊相关表
- `doctor_schedule` - 医生排班
- `registration` - 挂号记录
- `encounter` - 就诊记录
- `diagnosis` - 诊断记录

#### 药品相关表
- `drug` - 药品目录
- `prescription` - 处方主表
- `prescription_item` - 处方明细
- `dispense` - 发药记录
- `drug_inventory_txn` - 药品库存流水

#### 检验相关表
- `lab_test` - 检验项目
- `lab_order` - 检验申请
- `lab_order_item` - 检验明细
- `lab_result` - 检验结果

#### 住院相关表
- `ward` - 病区
- `bed` - 床位
- `admission` - 入院记录
- `bed_assignment` - 床位分配

#### 收费相关表
- `charge_catalog` - 收费项目目录
- `charge` - 费用记录
- `invoice` - 发票
- `invoice_line` - 发票明细
- `payment` - 支付记录
- `refund` - 退款记录

### 视图系统（40+个视图）

#### 公共视图
- `v_patient_public` - 患者公开信息
- `v_schedule_public` - 排班公开信息
- `v_encounter_summary` - 就诊概要
- `v_prescription_detail` - 处方明细
- `v_lab_result_detail` - 检验结果详情
- `v_invoice_summary` - 发票汇总

#### 员工视图
- `v_current_staff` - 当前登录员工
- `v_patient_reception` - 接待用患者视图
- `v_patient_clinical` - 临床用患者视图

#### 角色专用视图
- 医生：9个专用视图
- 护士：3个专用视图
- 药剂师：3个专用视图
- 检验技师：2个专用视图
- 收费员：4个专用视图
- 患者：5个专用视图

### 存储过程（20+个）

#### 患者管理
- `sp_patient_create` - 创建患者
- `sp_patient_update_contact` - 更新联系方式

#### 门诊管理
- `sp_outpatient_register` - 门诊挂号

#### 处方管理
- `sp_prescription_create` - 创建处方
- `sp_prescription_add_item` - 添加处方明细
- `sp_prescription_bill_sync` - 同步处方费用
- `sp_dispense_create` - 发药
- `sp_dispense_prescription` - 发药（带时间）

#### 检验管理
- `sp_lab_order_create` - 创建检验单
- `sp_lab_order_add_item` - 添加检验明细
- `sp_lab_order_mark_collected` - 标记已采样
- `sp_lab_order_bill_sync` - 同步检验费用
- `sp_lab_order_prepare_results` - 准备结果占位（**使用游标**）
- `sp_lab_result_upsert` - 录入/更新结果
- `sp_lab_result_verify` - 审核结果

#### 发票管理
- `sp_invoice_create_for_encounter` - 创建发票（**使用游标**）
- `sp_invoice_attach_unbilled_charges` - 追加费用（**使用游标**）
- `sp_invoice_void` - 作废发票

#### 支付管理
- `sp_payment_create` - 创建支付
- `sp_refund_create` - 创建退款

#### 住院管理
- `sp_inpatient_admit` - 办理入院（**使用游标**分配床位）
- `sp_bed_assignment_transfer` - 床位转移
- `sp_inpatient_discharge` - 办理出院

### 触发器（15+个）

#### 审计触发器
- 自动维护 `created_at`、`updated_at` 字段

#### 业务触发器
- 自动计算处方总金额
- 自动计算检验总金额
- 自动更新发票金额
- 自动更新支付状态
- 检查床位时间段冲突
- 检查挂号配额
- 同步费用状态

---

## 📊 功能矩阵

| 功能模块 | admin | doctor | nurse | pharmacist | lab_tech | cashier | reception | patient |
|---------|-------|--------|-------|------------|----------|---------|-----------|---------|
| 患者管理 | ✅ | 只读 | 只读 | - | - | - | ✅ | 只读(自己) |
| 排班管理 | ✅ | 只读 | - | - | - | - | 只读 | - |
| 挂号管理 | ✅ | 只读 | - | - | - | - | ✅ | 只读(自己) |
| 就诊管理 | ✅ | ✅ | 只读 | - | - | - | - | 只读(自己) |
| 处方管理 | ✅ | ✅ | - | 只读/发药 | - | - | - | 只读(自己) |
| 检验管理 | ✅ | 开单 | - | - | ✅ | - | - | 只读(自己) |
| 收费管理 | ✅ | - | - | - | - | ✅ | - | 只读(自己) |
| 药房管理 | ✅ | - | - | ✅ | - | - | - | - |
| 住院管理 | ✅ | - | ✅ | - | - | - | - | - |
| 员工管理 | ✅ | - | - | - | - | - | - | - |
| 科室管理 | ✅ | - | - | - | - | - | - | - |
| 统计报表 | ✅ | - | - | - | - | ✅ | - | - |

---

## 🔄 业务流程

### 1. 门诊流程

```
患者挂号 → 医生接诊 → 开立处方/检验 → 收费开票 → 药房发药/检验采样 → 完成就诊
```

**涉及的角色：**
1. **前台接待**：患者挂号（调用 `sp_outpatient_register`）
2. **医生**：创建就诊记录、开立处方、开立检验单
3. **收费员**：创建发票（调用 `sp_invoice_create_for_encounter`，使用游标）、处理支付（调用 `sp_payment_create`）
4. **药剂师**：发药（调用 `sp_dispense_create`）
5. **检验技师**：采样、录入结果（调用 `sp_lab_result_upsert`）

### 2. 住院流程

```
办理入院 → 分配床位 → 住院治疗 → 费用记录 → 办理出院 → 结算
```

**涉及的角色：**
1. **护士**：办理入院（调用 `sp_inpatient_admit`，使用游标自动分配床位）
2. **医生**：住院治疗、开立医嘱
3. **护士**：床位管理、转床
4. **收费员**：费用结算
5. **护士**：办理出院（调用 `sp_inpatient_discharge`）

### 3. 发药流程

```
医生开方 → 处方审核 → 收费 → 药房发药
```

**存储过程调用链：**
1. `sp_prescription_create` - 医生创建处方
2. `sp_prescription_bill_sync` - 同步处方费用
3. `sp_invoice_create_for_encounter` - 收费员开票（使用游标）
4. `sp_payment_create` - 收费员收款
5. `sp_dispense_create` - 药剂师发药

### 4. 检验流程

```
医生开单 → 收费 → 采样 → 检验 → 录入结果 → 审核报告
```

**存储过程调用链：**
1. `sp_lab_order_create` - 医生创建检验单
2. `sp_lab_order_bill_sync` - 同步检验费用
3. `sp_invoice_create_for_encounter` - 收费员开票
4. `sp_payment_create` - 收费员收款
5. `sp_lab_order_mark_collected` - 标记已采样
6. `sp_lab_result_upsert` - 检验技师录入结果
7. `sp_lab_result_verify` - 审核结果

---

## 🎨 UI设计

### 登录页面
- **美观的渐变背景**（深蓝色渐变，不是淡紫色）
- **大尺寸卡片**（最大宽度800px，适配全屏）
- **角色选择**下拉框
- **简洁设计**（删除了测试账号提示）

### 仪表盘
- 今日统计数据
- 快速操作入口
- 最近记录列表

### 列表页面
- 数据表格展示
- 搜索和筛选
- 分页功能
- 操作按钮

### 表单页面
- 验证规则
- 数据格式化
- 错误提示

---

## 🔐 安全特性

### 认证和授权
- **JWT令牌**：有效期24小时
- **角色验证**：每个API都检查角色权限
- **装饰器保护**：`@require_auth`、`@require_role`

### 数据安全
- **视图隔离**：不同角色看到不同数据
- **行级安全**：患者只能看自己的数据
- **列级安全**：敏感字段根据角色隐藏
- **SQL注入防护**：使用参数化查询

### 业务规则
- **触发器保护**：床位冲突、挂号配额
- **存储过程验证**：状态检查、权限验证
- **事务保护**：ACID特性保证

---

## 📈 技术亮点

### 1. 游标应用
- **发票创建**：遍历未开票费用
- **入院办理**：自动查找可用床位
- **检验准备**：批量创建结果占位

### 2. 触发器自动化
- 自动计算金额
- 自动更新状态
- 自动检查约束

### 3. 视图安全
- 最小披露原则
- SQL SECURITY DEFINER
- 基于用户名的行级过滤

### 4. ORM应用
- SQLAlchemy模型定义
- 关系映射
- 查询构建器

---

## 🎯 系统优势

1. **完整的权限体系**：8个角色，细粒度控制
2. **数据库驱动**：业务逻辑在数据库层实现
3. **高性能**：视图优化、索引支持
4. **易维护**：模块化设计、代码规范
5. **易扩展**：新增角色和功能容易
6. **安全可靠**：多层次安全保护

---

## 📚 技术栈

### 后端
- Python 3.8+
- Flask 3.0
- SQLAlchemy
- PyMySQL
- PyJWT

### 前端
- React 18
- Vite
- Ant Design 5
- React Router v6
- Axios

### 数据库
- MySQL 8.0+ / 9.x
- 30+ 数据表
- 40+ 视图
- 20+ 存储过程
- 15+ 触发器

---

**🎉 这是一个功能完整、设计合理、技术先进的医院管理系统！**

