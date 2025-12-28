# 基于角色的权限管理系统

## 🎯 完成的功能

### 1. 数据库角色权限系统（已存在）✅

数据库已经完整实现了8个角色的权限系统：

#### 角色列表
- **role_admin** - 超级管理员（全库权限）
- **role_doctor** - 医生（诊疗、处方、检验）
- **role_nurse** - 护士（住院、病区、床位）
- **role_pharmacist** - 药剂师（药品、调剂）
- **role_lab_tech** - 检验技师（检验结果录入）
- **role_cashier** - 收费员（收费、结算、支付）
- **role_reception** - 前台接待（挂号、预约、患者信息）
- **role_patient** - 患者（只读自己的数据）

#### 数据库视图系统
每个角色都有对应的视图，实现行级和列级安全：

**公共视图：**
- `v_patient_public` - 患者公开信息（不含敏感字段）
- `v_schedule_public` - 排班公开信息
- `v_current_staff` - 当前员工信息

**医生视图：**
- `v_doctor_my_schedule` - 我的排班
- `v_doctor_my_registrations` - 我的挂号
- `v_doctor_my_encounters` - 我的就诊记录
- `v_doctor_my_prescriptions_detail` - 我的处方明细
- `v_doctor_my_lab_results` - 我的检验结果

**护士视图：**
- `v_nurse_my_inpatients` - 我负责的住院患者
- `v_bed_occupancy` - 床位占用情况
- `v_inpatient_current` - 当前住院患者

**药剂师视图：**
- `v_pharmacy_dispense_queue` - 待发药队列
- `v_pharmacy_dispense_detail` - 发药明细

**检验技师视图：**
- `v_lab_worklist` - 检验工作列表
- `v_lab_my_items` - 我负责的检验项目

**收费员视图：**
- `v_cashier_unbilled_charges` - 未开票费用
- `v_invoice_summary` - 发票汇总
- `v_payment_refund_detail` - 支付退款明细

**患者视图：**
- `v_patient_my_encounters` - 我的就诊记录
- `v_patient_my_prescriptions` - 我的处方
- `v_patient_my_lab_results` - 我的检验结果
- `v_patient_my_invoices` - 我的账单

### 2. 存储过程系统（含游标）✅

#### 已实现的存储过程
数据库包含多个存储过程，使用游标处理复杂业务逻辑：

**患者管理：**
- `sp_patient_create` - 创建患者
- `sp_patient_update_contact` - 更新联系方式

**门诊管理：**
- `sp_outpatient_register` - 门诊挂号

**发票管理（含游标）：**
- `sp_invoice_create_for_encounter` - 为就诊创建发票（**使用游标**遍历未开票费用）
- `sp_invoice_attach_unbilled_charges` - 追加未开票费用（**使用游标**）
- `sp_invoice_void` - 作废发票

**支付管理：**
- `sp_payment_create` - 创建支付
- `sp_refund_create` - 创建退款

**住院管理：**
- `sp_inpatient_admit` - 办理入院
- `sp_bed_assignment_transfer` - 床位转移
- `sp_inpatient_discharge` - 办理出院

**药房管理：**
- `sp_dispense_create` - 创建发药记录
- `sp_dispense_prescription` - 发药（处方）

**检验管理：**
- `sp_lab_order_create` - 创建检验申请
- `sp_lab_result_upsert` - 更新检验结果
- `sp_lab_result_verify` - 审核检验结果

#### 游标示例

**sp_invoice_create_for_encounter** 存储过程使用游标：

```sql
DECLARE cur_unbilled_charges CURSOR FOR
  SELECT c.charge_id
  FROM charge c
  WHERE c.encounter_id = p_encounter_id
    AND c.status = 'UNBILLED'
    AND c.amount > 0
  ORDER BY c.charged_at, c.charge_id
  FOR UPDATE;

OPEN cur_unbilled_charges;
read_loop: LOOP
  FETCH cur_unbilled_charges INTO v_charge_id;
  IF v_done = 1 THEN
    LEAVE read_loop;
  END IF;
  
  INSERT INTO invoice_line (invoice_id, charge_id)
  VALUES (o_invoice_id, v_charge_id);
  
  SET o_line_count = o_line_count + 1;
END LOOP;
CLOSE cur_unbilled_charges;
```

### 3. 后端权限系统 ✅

#### 认证模块（auth.py）
- JWT令牌生成和验证
- 角色权限配置
- 装饰器：`@require_auth`、`@require_role`
- 权限检查函数

#### 认证路由（routes/auth.py）
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/current-user` - 获取当前用户
- `GET /api/auth/roles` - 获取所有角色
- `POST /api/auth/logout` - 用户登出

#### 存储过程调用路由（routes/procedures.py）
- `POST /api/procedures/invoice/create-for-encounter` - 调用存储过程创建发票（含游标）
- `POST /api/procedures/payment/create` - 调用存储过程创建支付
- `POST /api/procedures/patient/create` - 调用存储过程创建患者
- `POST /api/procedures/registration/create` - 调用存储过程挂号
- `GET /api/procedures/list` - 列出所有存储过程（管理员）

### 4. 前端权限系统 ✅

#### 登录页面（Login.jsx）
- 美观的登录界面
- 角色选择下拉框
- 8个角色可选
- JWT令牌管理

#### 动态菜单
根据用户角色显示不同的菜单项：

**管理员（admin）：**
- 全部菜单（仪表盘、患者、员工、科室、排班、挂号、就诊、收费、统计）

**医生（doctor）：**
- 仪表盘、患者管理、排班管理、挂号管理、就诊管理

**护士（nurse）：**
- 仪表盘、患者管理、就诊管理、住院管理

**药剂师（pharmacist）：**
- 仪表盘、药房管理、处方管理

**检验技师（lab_tech）：**
- 仪表盘、检验申请、检验结果

**收费员（cashier）：**
- 仪表盘、收费管理、支付管理、统计报表

**前台接待（reception）：**
- 仪表盘、患者管理、排班管理、挂号管理

**患者（patient）：**
- 仪表盘、我的信息、我的就诊记录

#### 用户界面
- 右上角显示当前用户和角色
- 用户下拉菜单（切换角色、退出登录）
- Token自动附加到请求头

### 5. 权限控制

#### 后端权限控制
```python
# 要求特定角色才能访问
@require_role('admin', 'cashier')
def create_invoice():
    # 只有管理员和收费员能开发票
    pass

# 检查权限
if check_permission('patients.update'):
    # 允许操作
    pass
```

#### 只读字段标识
每个角色都定义了只读字段列表：

```python
'doctor': {
    'readonly_fields': ['patient.id_card_no', 'invoice', 'payment']
}
```

前端可以根据这个列表禁用或隐藏字段。

## 🚀 使用指南

### 1. 初始化数据库

```bash
cd database

# 执行所有脚本（按顺序）
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
mysql -u root -p hospital_test < seed_simple.sql
mysql --commands -u root -p < security.sql     # ✅ 创建角色和视图
mysql --commands -u root -p < routines.sql     # ✅ 创建存储过程
mysql --commands -u root -p < sql/security/5_grants_routines.sql  # ✅ 授予执行权限
```

### 2. 启动后端

```bash
cd backend
pip install -r requirements.txt  # 安装pyjwt
python app.py
```

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev
```

### 4. 登录测试

访问 http://localhost:3000

#### 测试账号
- **超级管理员**：admin / admin123
- **其他角色**：任意用户名 / 任意密码（≥6位）

### 5. 测试存储过程

#### 创建发票（使用游标）
```bash
POST /api/procedures/invoice/create-for-encounter
Authorization: Bearer <token>

{
  "encounter_id": 1,
  "note": "门诊费用"
}
```

#### 创建支付
```bash
POST /api/procedures/payment/create
Authorization: Bearer <token>

{
  "invoice_id": 1,
  "method": "CASH",
  "amount": 100.00
}
```

## 📊 权限矩阵

| 功能模块 | admin | doctor | nurse | pharmacist | lab_tech | cashier | reception | patient |
|---------|-------|--------|-------|------------|----------|---------|-----------|---------|
| 患者管理 | ✅ | 只读 | 只读 | - | - | - | ✅ | 只读(自己) |
| 排班管理 | ✅ | 只读 | - | - | - | - | 只读 | - |
| 挂号管理 | ✅ | 只读 | - | - | - | - | ✅ | 只读(自己) |
| 就诊管理 | ✅ | ✅ | 只读 | - | - | - | - | 只读(自己) |
| 处方管理 | ✅ | ✅ | - | 只读 | - | - | - | 只读(自己) |
| 检验管理 | ✅ | 开单 | - | - | ✅ | - | - | 只读(自己) |
| 收费管理 | ✅ | - | - | - | - | ✅ | - | 只读(自己) |
| 员工管理 | ✅ | - | - | - | - | - | - | - |
| 科室管理 | ✅ | - | - | - | - | - | - | - |
| 统计报表 | ✅ | - | - | - | - | ✅ | - | - |

## 🔐 安全特性

1. **JWT令牌**：有效期24小时
2. **密码哈希**：SHA256（生产应使用bcrypt）
3. **角色验证**：每个API都检查角色权限
4. **视图安全**：数据库视图限制数据访问
5. **行级安全**：患者只能看自己的数据
6. **列级安全**：敏感字段根据角色隐藏

## 📝 扩展建议

### 1. 增强密码安全
使用bcrypt替换当前的SHA256：

```python
import bcrypt
password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
```

### 2. 数据库用户绑定
创建MySQL用户对应每个角色：

```sql
CREATE USER 'doctor1'@'localhost' IDENTIFIED BY 'password';
GRANT role_doctor TO 'doctor1'@'localhost';
SET DEFAULT ROLE role_doctor TO 'doctor1'@'localhost';
```

### 3. 审计日志
记录所有操作到audit_log表：

```python
def log_action(user_id, action, table, record_id):
    # 记录到数据库
    pass
```

### 4. 只读字段UI
在前端根据`readonly_fields`自动禁用字段：

```javascript
const isReadonly = user.readonly_fields.includes('patient.id_card_no')
<Input disabled={isReadonly} />
```

## ✅ 检查清单

- [x] 8个角色定义完成
- [x] 数据库视图系统完成
- [x] 存储过程实现（含游标）
- [x] 后端JWT认证
- [x] 后端角色权限控制
- [x] 后端存储过程调用API
- [x] 前端登录页面
- [x] 前端角色选择
- [x] 前端动态菜单
- [x] 前端用户信息显示
- [x] 超级管理员功能
- [x] 权限验证装饰器
- [x] 只读字段配置

---

**🎉 完整的基于角色的权限管理系统已实现！**

现在系统支持：
1. ✅ 角色选择登录
2. ✅ 根据角色显示不同视图和菜单
3. ✅ 细粒度权限控制（增删查改）
4. ✅ 只读字段标识
5. ✅ 超级管理员直接访问数据库
6. ✅ 调用存储过程和游标

