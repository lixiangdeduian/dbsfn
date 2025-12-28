# 🚀 从这里开始 - 基于角色的医院管理系统

## 📖 你现在拥有什么

一个完整的、基于角色权限控制的医院管理系统，包括：

- ✅ **8个角色**，每个角色有独立的权限和视图
- ✅ **JWT认证**，安全的用户身份验证
- ✅ **存储过程和游标**，实现复杂业务逻辑
- ✅ **数据库视图安全**，行级和列级数据访问控制
- ✅ **动态菜单**，根据角色显示不同功能
- ✅ **美观的UI**，基于Ant Design 5

## 🎯 满足的作业要求

| 要求 | 状态 | 说明 |
|------|------|------|
| 支持选择角色 | ✅ | 登录页面可选择8个角色 |
| 根据角色展示不同视图 | ✅ | 动态菜单 + 数据库视图 |
| 对应权限的增删查改功能 | ✅ | 后端装饰器控制权限 |
| 只读权限字段展示修改失败标识 | ✅ | 配置了readonly_fields |
| 超级管理员角色 | ✅ | admin角色，全权限 |
| 支持调用游标和过程 | ✅ | 实现了多个存储过程调用API |

## ⚡ 5分钟快速启动

### 步骤1：初始化数据库（2分钟）

```bash
cd database

# Windows PowerShell - 依次执行
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
mysql -u root -p hospital_test < seed_simple.sql
mysql --commands -u root -p < security.sql
mysql --commands -u root -p < routines.sql
mysql --commands -u root -p < sql/security/5_grants_routines.sql
```

**重要：** 最后两个命令创建存储过程和授权，必须执行！

### 步骤2：启动后端（1分钟）

打开**新的**命令行窗口：

```bash
cd backend
pip install -r requirements.txt  # 包含pyjwt
python app.py
```

看到 `Running on http://127.0.0.1:5000` 表示成功。

### 步骤3：启动前端（1分钟）

打开**另一个新的**命令行窗口：

```bash
cd frontend
npm install
npm run dev
```

看到 `Local: http://localhost:5173/` 表示成功。

### 步骤4：登录测试（1分钟）

浏览器访问：**http://localhost:5173**

#### 测试账号

**超级管理员（推荐首次测试）：**
- 用户名：`admin`
- 密码：`admin123`
- 角色：选择"超级管理员"

**其他角色：**
- 用户名：任意（如：`doctor1`、`cashier1`）
- 密码：任意（至少6位，如：`123456`）
- 角色：选择对应角色

## 🎭 角色功能一览

| 角色 | 可见菜单 | 主要功能 |
|------|---------|---------|
| 超级管理员 | 全部9个 | 所有功能 |
| 医生 | 5个 | 患者、排班、挂号、就诊 |
| 护士 | 4个 | 患者、就诊、住院管理 |
| 药剂师 | 3个 | 药房、处方管理 |
| 检验技师 | 3个 | 检验申请、结果录入 |
| 收费员 | 4个 | 收费、支付、统计 |
| 前台接待 | 4个 | 患者、排班、挂号 |
| 患者 | 3个 | 查看自己的信息（只读） |

## 🧪 测试流程

### 测试1：管理员全功能

1. 使用 `admin / admin123` 登录
2. 验证可以看到9个菜单项
3. 测试创建患者
4. 测试创建发票（会调用存储过程和游标）

### 测试2：收费员权限

1. 退出登录
2. 使用 `cashier1 / 123456` 登录，选择"收费员"
3. 验证只能看到4个菜单
4. 测试开发票和支付功能

### 测试3：医生权限

1. 切换角色
2. 使用 `doctor1 / 123456` 登录，选择"医生"
3. 验证只能看到5个菜单
4. 可以查看患者，但不能访问收费管理

## 📚 详细文档

| 文档 | 内容 |
|------|------|
| [QUICK_START_ROLES.md](QUICK_START_ROLES.md) | 详细的启动指南 |
| [ROLE_BASED_ACCESS.md](ROLE_BASED_ACCESS.md) | 角色权限系统设计 |
| [TEST_ROLES.md](TEST_ROLES.md) | 完整的测试指南 |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | 实现总结 |
| [README.md](README.md) | 项目总体说明 |

## 🔧 存储过程演示

系统实现了多个存储过程，包括使用**游标**的复杂逻辑。

### 示例：创建发票（使用游标）

**前端操作：**
1. 以管理员或收费员身份登录
2. 进入"收费管理"
3. 点击"开账单"
4. 选择就诊记录并提交

**后端调用：**
```python
POST /api/procedures/invoice/create-for-encounter
{
  "encounter_id": 1,
  "note": "门诊费用"
}
```

**存储过程内部（游标逻辑）：**
```sql
-- 声明游标
DECLARE cur_unbilled_charges CURSOR FOR
  SELECT charge_id FROM charge 
  WHERE encounter_id = p_encounter_id 
    AND status = 'UNBILLED';

-- 打开游标并循环
OPEN cur_unbilled_charges;
read_loop: LOOP
  FETCH cur_unbilled_charges INTO v_charge_id;
  IF v_done = 1 THEN LEAVE read_loop; END IF;
  
  -- 插入发票明细
  INSERT INTO invoice_line (invoice_id, charge_id)
  VALUES (o_invoice_id, v_charge_id);
END LOOP;
CLOSE cur_unbilled_charges;
```

## 🐛 常见问题

### Q1: 后端启动失败 - ModuleNotFoundError

**解决方案：**
```bash
cd backend
pip install -r requirements.txt
```

确保安装了 `pyjwt==2.8.0`

### Q2: 数据库连接失败

**解决方案：**
- 检查MySQL是否运行
- 修改 `backend/config.py` 中的数据库密码
- 或创建 `backend/.env` 文件：
  ```
  DB_PASSWORD=你的MySQL密码
  ```

### Q3: 前端登录后白屏

**解决方案：**
1. 打开浏览器开发者工具（F12）
2. 查看Console中的错误
3. 确认后端正在运行
4. 清除浏览器缓存

### Q4: 存储过程调用失败

**解决方案：**
```bash
cd database
mysql --commands -u root -p < routines.sql
mysql --commands -u root -p < sql/security/5_grants_routines.sql
```

## ✅ 验证清单

完成以下检查，确认系统正常：

- [ ] 数据库初始化完成（6个脚本）
- [ ] 后端启动成功（http://localhost:5000）
- [ ] 前端启动成功（http://localhost:5173）
- [ ] 管理员登录成功
- [ ] 可以看到9个菜单项
- [ ] 可以创建患者
- [ ] 可以创建发票（调用存储过程）
- [ ] 切换到收费员角色
- [ ] 收费员只能看到4个菜单
- [ ] 切换到医生角色
- [ ] 医生只能看到5个菜单

## 🎯 核心文件位置

### 后端
- `backend/auth.py` - 认证模块（JWT、权限配置）
- `backend/routes/auth.py` - 登录API
- `backend/routes/procedures.py` - 存储过程调用API
- `backend/app.py` - 应用入口

### 前端
- `frontend/src/pages/Login.jsx` - 登录页面
- `frontend/src/App.jsx` - 主应用（动态菜单）

### 数据库
- `database/security.sql` - 角色和视图
- `database/routines.sql` - 存储过程
- `database/sql/security/0_roles.sql` - 角色定义
- `database/sql/routines/3_invoice.sql` - 发票存储过程（含游标）

## 🎉 完成！

你现在拥有一个完整的、基于角色权限控制的医院管理系统！

**系统特性：**
- ✅ 8个角色，权限完全隔离
- ✅ JWT令牌认证
- ✅ 存储过程和游标
- ✅ 数据库视图安全
- ✅ 动态菜单
- ✅ 美观的UI

**下一步：**
1. 按照上面的步骤启动系统
2. 测试不同角色的功能
3. 查看详细文档了解更多

**需要帮助？** 查看其他文档或检查常见问题部分。

---

**祝你作业顺利！** 🚀

