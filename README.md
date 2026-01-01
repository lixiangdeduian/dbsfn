# 社区医院门诊管理系统

一个基于 Python Flask + React + MySQL 的社区医院门诊管理系统，实现患者预约、挂号、就诊、缴费、员工管理、排班管理、统计查询等全流程功能。

## 🌟 核心功能：基于角色的权限控制系统

系统支持**8个不同角色**的权限管理，**无需登录，右上角直接切换角色**：

| 角色 | 功能菜单 | 主要权限 | 数据范围 |
|------|---------|---------|---------|
| **超级管理员** | 12个 | 全库权限，所有功能 | 全部数据 |
| **医生** | 5个 | 患者诊疗、处方开立、检验开单 | 自己的患者 |
| **护士** | 4个 | 住院管理、床位分配、护理记录 | 科室患者 |
| **药剂师** | 3个 | 药房管理、处方调剂、发药 | 所有处方 |
| **检验技师** | 4个 | 检验管理、结果录入、报告审核 | 所有检验 |
| **收费员** | 4个 | 收费开票、支付管理、统计报表 | 所有账单 |
| **前台接待** | 4个 | 患者登记、预约挂号、信息维护 | 全部患者 |
| **患者** | 2个 | 查看个人医疗记录（**只读**） | **仅自己** |

**核心特性：**
- ✅ **右上角角色切换** - 无需登录，一键切换
- ✅ **动态菜单** - 根据角色显示对应功能
- ✅ **存储过程调用** - 包含3个使用游标的存储过程
- ✅ **数据库视图安全** - 行级和列级权限控制
- ✅ **8个数据库用户** - 每个角色对应独立账号

**详细文档：** 
- [患者角色更新说明](PATIENT_ROLE_UPDATE.md) - 🆕 患者角色完整实现
- [完整角色权限对照](ROLE_PERMISSIONS_COMPLETE.md) - 8个角色详细权限
- [角色测试指南](ROLE_TESTING_GUIDE.md) - 各角色测试清单
- [系统功能完整文档](SYSTEM_FEATURES.md) - 详细功能介绍
- [数据库设计文档](database/README.md) - 数据库结构说明

## 📋 目录

- [功能特性](#功能特性)
- [技术栈](#技术栈)
- [系统架构](#系统架构)
- [环境要求](#环境要求)
- [安装部署](#安装部署)
  - [Windows 系统](#windows-系统)
  - [macOS 系统](#macos-系统)
  - [Linux 系统](#linux-系统)
- [使用说明](#使用说明)
- [API 文档](#api-文档)
- [常见问题](#常见问题)

## 🎯 功能特性

### 患者端功能（患者角色）
- ✅ 查看个人基本信息（姓名、性别、血型、过敏史等）
- ✅ 查看历史就诊记录
- ✅ 查看历史处方和用药
- ✅ 查看检验结果报告
- ✅ 查看费用账单和支付情况
- ⚠️ **完全只读**，无任何修改权限
- 🔒 **数据隔离**，只能看到自己的数据

### 前台工作人员功能
- ✅ 患者到院登记
- ✅ 处理预约挂号
- ✅ 患者缴费结算
- ✅ 查看患者信息

### 管理人员功能
- ✅ 医生排班管理（增加、修改、删除）
- ✅ 账单查询统计（按日期/科室/医生）
- ✅ 患者详细信息查询
- ✅ 员工信息查询和管理
- ✅ 科室管理

### 统计报表
- ✅ 今日/本月就诊人次统计
- ✅ 收入统计（按日期、科室、医生）
- ✅ 医生工作量统计
- ✅ 科室收入统计

## 🛠 技术栈

### 后端
- **语言**: Python 3.8+
- **框架**: Flask 3.0
- **ORM**: SQLAlchemy
- **数据库**: MySQL 8.0+ / MySQL 9.x
- **数据库驱动**: PyMySQL

### 前端
- **框架**: React 18
- **构建工具**: Vite
- **UI 库**: Ant Design 5
- **路由**: React Router v6
- **HTTP 客户端**: Axios
- **日期处理**: Day.js

## 🏗 系统架构

```
系统架构图:
┌─────────────┐
│  React前端   │ (端口: 3000)
│   Ant Design │
└──────┬──────┘
       │ HTTP/REST API
       ↓
┌─────────────┐
│  Flask后端   │ (端口: 5000)
│  SQLAlchemy  │
└──────┬──────┘
       │ PyMySQL
       ↓
┌─────────────┐
│   MySQL DB  │ (端口: 3306)
│hospital_test│
└─────────────┘
```

## 💻 环境要求

### 必需软件
1. **Python 3.8+**
2. **Node.js 16+** 和 **npm 或 yarn**
3. **MySQL 8.0+** 或 **MySQL 9.x**
4. **Git** (可选，用于克隆代码)

### 系统支持
- ✅ Windows 10/11
- ✅ macOS 10.15+
- ✅ Linux (Ubuntu 20.04+, CentOS 8+, 等)

## 📦 安装部署

### 前置条件

#### 1. 检查 Python 版本
```bash
# Windows
python --version

# macOS/Linux
python3 --version
```
应该显示 Python 3.8 或更高版本。

#### 2. 检查 Node.js 版本
```bash
node --version
npm --version
```
Node.js 应该是 16.0 或更高版本。

#### 3. 检查 MySQL 服务
确保 MySQL 服务已启动：
```bash
# Windows (PowerShell 管理员模式)
Get-Service MySQL*

# macOS
brew services list | grep mysql

# Linux
sudo systemctl status mysql
```

---

### Windows 系统

#### 步骤 1: 安装依赖软件

**安装 Python:**
1. 访问 https://www.python.org/downloads/
2. 下载 Python 3.8+ 安装包
3. 运行安装程序，**勾选 "Add Python to PATH"**
4. 点击 "Install Now"

**安装 Node.js:**
1. 访问 https://nodejs.org/
2. 下载 LTS 版本
3. 运行安装程序，一路 "Next"

**安装 MySQL:**
1. 访问 https://dev.mysql.com/downloads/installer/
2. 下载 MySQL Installer
3. 运行安装程序，选择 "Developer Default"
4. 设置 root 密码（记住这个密码！）

#### 步骤 2: 初始化数据库

1. 打开命令提示符 (cmd) 或 PowerShell
2. 进入数据库目录并执行 SQL 脚本：

```powershell
# 进入项目的 database 目录
cd D:\Desktop\temp\dbsfn\database

# 执行数据库初始化脚本
mysql --commands -u root -p < schema.sql
# 输入 MySQL root 密码

mysql --commands -u root -p < triggers.sql
mysql -u root -p --default-character-set=utf8mb4 hospital_test < seed_simple.sql
mysql --commands -u root -p < security.sql
mysql --commands -u root -p < routines.sql

# 可选：授予存储过程执行权限
mysql --commands -u root -p < sql/security/5_grants_routines.sql
```

#### 步骤 3: 配置后端

1. 进入后端目录：
```powershell
cd ..\backend
```

2. 创建 Python 虚拟环境：
```powershell
python -m venv venv
```

3. 激活虚拟环境：
```powershell
venv\Scripts\activate
```

4. 安装 Python 依赖：
```powershell
pip install -r requirements.txt
```

5. 创建环境配置文件：
```powershell
# 复制模板文件
copy env.template .env

# 使用记事本编辑 .env 文件
notepad .env
```

6. 编辑 `.env` 文件，修改数据库配置：
```ini
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=你的MySQL密码
DB_NAME=hospital_test

# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-here

# Server Configuration
HOST=0.0.0.0
PORT=5000
```

#### 步骤 4: 配置前端

1. 打开新的命令提示符窗口
2. 进入前端目录：
```powershell
cd D:\Desktop\temp\dbsfn\frontend
```

3. 安装 Node.js 依赖：
```powershell
npm install
```

如果遇到网络问题，可以使用国内镜像：
```powershell
npm config set registry https://registry.npmmirror.com
npm install
```

#### 步骤 5: 启动系统

**方法一：使用启动脚本（推荐）**

1. 启动后端（双击运行 `start_backend.bat`）
   或在命令行中：
```powershell
cd D:\Desktop\temp\dbsfn
start_backend.bat
```

2. 启动前端（双击运行 `start_frontend.bat`）
   或在命令行中：
```powershell
cd D:\Desktop\temp\dbsfn
start_frontend.bat
```

**方法二：手动启动**

1. 启动后端：
```powershell
cd D:\Desktop\temp\dbsfn\backend
venv\Scripts\activate
python app.py
```

2. 启动前端（新窗口）：
```powershell
cd D:\Desktop\temp\dbsfn\frontend
npm run dev
```

#### 步骤 6: 访问系统

打开浏览器访问：http://localhost:3000

---

### macOS 系统

#### 步骤 1: 安装依赖软件

**安装 Homebrew（如果尚未安装）:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**安装 Python:**
```bash
brew install python@3.10
```

**安装 Node.js:**
```bash
brew install node
```

**安装 MySQL:**
```bash
brew install mysql
brew services start mysql

# 设置 root 密码
mysql_secure_installation
```

#### 步骤 2: 初始化数据库

```bash
# 进入数据库目录
cd /path/to/dbsfn/database

# 执行 SQL 脚本（按顺序执行）
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
mysql -u root -p --default-character-set=utf8mb4 hospital_test < seed_simple.sql
mysql --commands -u root -p < security.sql
mysql --commands -u root -p < routines.sql
```

#### 步骤 3: 配置后端

```bash
# 进入后端目录
cd ../backend

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 创建配置文件
cp env.template .env

# 编辑配置文件
nano .env
```

修改 `.env` 文件中的数据库配置。

#### 步骤 4: 配置前端

```bash
# 进入前端目录
cd ../frontend

# 安装依赖
npm install
```

#### 步骤 5: 启动系统

**方法一：使用启动脚本**

```bash
# 给脚本添加执行权限
chmod +x start_backend.sh start_frontend.sh

# 启动后端（新终端窗口）
./start_backend.sh

# 启动前端（新终端窗口）
./start_frontend.sh
```

**方法二：手动启动**

```bash
# 终端 1 - 启动后端
cd backend
source venv/bin/activate
python3 app.py

# 终端 2 - 启动前端
cd frontend
npm run dev
```

#### 步骤 6: 访问系统

打开浏览器访问：http://localhost:3000

---

### Linux 系统

#### 步骤 1: 安装依赖软件

**Ubuntu/Debian:**
```bash
# 更新包列表
sudo apt update

# 安装 Python
sudo apt install python3 python3-pip python3-venv

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 MySQL
sudo apt install mysql-server
sudo systemctl start mysql
sudo mysql_secure_installation
```

**CentOS/RHEL:**
```bash
# 安装 Python
sudo yum install python3 python3-pip

# 安装 Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 安装 MySQL
sudo yum install mysql-server
sudo systemctl start mysqld
sudo mysql_secure_installation
```

#### 步骤 2-6: 与 macOS 相同

参考 macOS 的步骤 2-6，命令完全一样。

---

## 📖 使用说明

### 1. 患者管理
- 点击侧边栏 "患者管理"
- 点击 "新建患者" 按钮
- 填写患者信息（姓名、性别、身份证号、联系电话等）
- 点击 "提交" 保存

### 2. 排班管理
- 点击侧边栏 "排班管理"
- 点击 "新建排班" 按钮
- 选择医生、科室、日期、时间、号源数量
- 点击 "提交" 保存

### 3. 预约挂号
- 点击侧边栏 "挂号管理"
- 点击 "预约挂号" 按钮
- 选择患者、就诊日期、科室
- 在可预约排班表中点击 "选择"
- 填写主诉（可选）
- 点击 "提交预约"

### 4. 到院登记
- 点击侧边栏 "就诊管理"
- 点击 "到院登记" 按钮
- 选择患者、科室、医生
- 点击 "提交登记"

### 5. 缴费结算
- 点击侧边栏 "收费管理"
- 点击 "开账单" 按钮
- 选择患者、输入金额
- 点击 "开具账单"
- 在发票列表中点击 "收款"
- 选择支付方式、输入金额
- 点击 "确认收款"

### 6. 查看统计
- 点击侧边栏 "统计报表"
- 选择日期范围
- 点击 "查询" 查看统计数据

## 📡 API 文档

### 基础 URL
```
http://localhost:5000/api
```

### 患者管理
- `GET /patients/` - 获取患者列表
- `GET /patients/:id` - 获取患者详情
- `POST /patients/` - 创建患者
- `PUT /patients/:id` - 更新患者
- `DELETE /patients/:id` - 删除患者

### 排班管理
- `GET /schedules/` - 获取排班列表
- `GET /schedules/:id` - 获取排班详情
- `POST /schedules/` - 创建排班
- `PUT /schedules/:id` - 更新排班
- `DELETE /schedules/:id` - 删除排班

### 挂号管理
- `GET /registrations/` - 获取挂号列表
- `GET /registrations/:id` - 获取挂号详情
- `POST /registrations/` - 创建挂号
- `POST /registrations/:id/cancel` - 取消挂号

### 就诊管理
- `GET /encounters/` - 获取就诊列表
- `GET /encounters/:id` - 获取就诊详情
- `POST /encounters/` - 创建就诊
- `POST /encounters/:id/close` - 结束就诊

### 收费管理
- `GET /invoices/` - 获取发票列表
- `GET /invoices/:id` - 获取发票详情
- `POST /invoices/` - 创建发票
- `POST /invoices/:id/void` - 作废发票

### 支付管理
- `GET /payments/` - 获取支付列表
- `POST /payments/` - 创建支付

### 统计报表
- `GET /statistics/dashboard` - 仪表盘数据
- `GET /statistics/revenue` - 收入统计
- `GET /statistics/encounters` - 就诊统计
- `GET /statistics/department-revenue` - 科室收入
- `GET /statistics/doctor-workload` - 医生工作量

## ❓ 常见问题

### 1. 后端启动失败

**问题**: `ModuleNotFoundError: No module named 'flask'`

**解决方案**:
```bash
# 确保已激活虚拟环境
# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

# 重新安装依赖
pip install -r requirements.txt
```

### 2. 数据库连接失败

**问题**: `Can't connect to MySQL server`

**解决方案**:
1. 检查 MySQL 服务是否启动
2. 检查 `.env` 文件中的数据库配置
3. 确认密码正确
4. 检查端口是否被占用

```bash
# Windows
Get-Service MySQL*

# macOS
brew services list | grep mysql

# Linux
sudo systemctl status mysql
```

### 3. 前端启动失败

**问题**: `npm ERR! code ELIFECYCLE`

**解决方案**:
```bash
# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

### 4. 端口被占用

**问题**: `Address already in use`

**解决方案**:

**Windows:**
```powershell
# 查找占用端口的进程
netstat -ano | findstr :5000

# 杀掉进程（替换 PID）
taskkill /PID <进程ID> /F
```

**macOS/Linux:**
```bash
# 查找占用端口的进程
lsof -i :5000

# 杀掉进程
kill -9 <PID>
```

### 5. CORS 错误

**问题**: 前端无法访问后端 API

**解决方案**:
检查后端 `config.py` 中的 CORS 配置是否包含前端地址。

### 6. SQL 脚本执行失败

**问题**: `ERROR 1064: You have an error in your SQL syntax`

**解决方案**:
确保使用了 `--commands` 参数：
```bash
mysql --commands -u root -p < schema.sql
```

## 📝 注意事项

1. **安全性**: 本系统为教学演示项目，生产环境需要：
   - 添加用户认证和授权
   - 使用 HTTPS
   - 加密敏感数据
   - 添加更多的输入验证

2. **数据备份**: 定期备份数据库：
```bash
mysqldump -u root -p hospital_test > backup.sql
```

3. **日志记录**: 生产环境需要配置日志系统

4. **性能优化**: 
   - 添加数据库索引
   - 使用缓存（Redis）
   - 负载均衡

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 👥 联系方式

如有问题，请联系项目维护者。

---

**祝你使用愉快！** 🎉

