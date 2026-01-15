# Hospital Management System (HMS)

这是一个全栈医院管理系统演示项目，模拟了真实的软件工程开发协作与性能调优过程。本项目包含数据库设计、后端 API 服务以及前端管理界面。

## 📋 目录结构

- **database/**: 包含完整的数据库设计 SQL 脚本（Schema, Data, Security, Routines, Triggers）。
- **backend/**: 基于 Node.js (Express + Sequelize) 的后端服务。
- **frontend/**: 纯静态前端界面，通过 API 与后端交互。

---

## 🚀 快速开始

请按照以下步骤，从零开始运行本项目。

### 1. 环境准备

确保你的开发环境已安装以下软件：
- **MySQL 8.0+** (推荐 8.0 或 9.0)
- **Node.js 18+** (推荐 LTS 版本)
- **npm** (通常随 Node.js 安装)

### 2. 数据库初始化

我们需要创建一个名为 `hospital_test` 的数据库，并依次执行 SQL 脚本来构建表结构、导入数据和设置权限。

**步骤 2.1: 进入数据库目录**

打开终端，进入项目的 `database` 目录：

```bash
cd database
```

**步骤 2.2: 创建数据库并导入数据**

请依次执行以下命令（假设你的 MySQL 用户名为 `root`，需要输入密码）：

> ⚠️ **注意**: 脚本执行顺序非常重要，请勿乱序执行。

```bash
# 1. 创建数据库
mysql -u root -p -e "DROP DATABASE IF EXISTS hospital_test; CREATE DATABASE hospital_test CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

# 2. 导入表结构 (Schema)
mysql --default-character-set=utf8mb4 --commands -u root -p hospital_test < schema.sql

# 3. 导入触发器 (Triggers)
mysql --default-character-set=utf8mb4 --commands -u root -p hospital_test < triggers.sql

# 4. 导入存储过程与函数 (Routines)
mysql --default-character-set=utf8mb4 --commands -u root -p hospital_test < routines.sql

# 5. 导入安全策略与角色 (Security)
mysql --default-character-set=utf8mb4 --commands -u root -p hospital_test < security.sql

# 6. 导入初始种子数据 (Seed Data) - 此步会生成大量模拟数据
mysql --default-character-set=utf8mb4 --commands -u root -p hospital_test < seed.sql
```

**步骤 2.3: 授予数据库用户角色权限 (关键步骤)**

本项目利用 MySQL 的 Role (角色) 机制进行权限控制。后端服务会根据前端选择的角色，在数据库连接会话中执行 `SET ROLE`。
因此，你需要将项目中定义的所有角色授予给你的数据库连接用户（例如 `root`）。

请登录 MySQL 执行以下 SQL：

```bash
mysql -u root -p
```

在 MySQL 交互命令行中执行：

```sql
-- 将所有定义的业务角色授予 root 用户 (请根据实际连接用户修改 'root'@'localhost')
GRANT role_admin, role_reception, role_doctor, role_nurse, role_pharmacist, role_lab_tech, role_cashier, role_patient TO 'root'@'localhost';

-- 激活这些角色
SET DEFAULT ROLE ALL TO 'root'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;

-- 退出
EXIT;
```

> **为什么需要这一步？**
> 后端代码在处理请求时，会执行 `SET ROLE role_doctor;` 等命令。如果连接数据库的 `root` 用户没有被授予 `role_doctor` 权限，该命令会失败，导致 "is not granted" 错误。

### 3. 后端服务配置与启动

**步骤 3.1: 进入后端目录并安装依赖**

```bash
cd ../backend
npm install
```

**步骤 3.2: 配置环境变量**

复制示例配置文件：

```bash
cp .env.example .env
```

打开 `.env` 文件，根据你的数据库配置进行修改：

```ini
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root          # 你的数据库用户名
DB_PASSWORD=your_password  # 你的数据库密码
DB_NAME=hospital_test
PORT=3000
```

**步骤 3.3: 启动后端服务**

```bash
npm start
```

如果看到类似 `Server is running on port 3000` 的日志，说明启动成功。

### 4. 访问前端界面

本项目的前端页面由后端服务静态托管。

打开浏览器，访问：

👉 **http://localhost:3000**

### 5. 功能验证指南

进入系统后，你可以尝试以下操作来验证系统是否正常运行：

1.  **切换角色**: 在左上角下拉菜单选择不同的角色（如 `Doctor` vs `Receptionist`）。
2.  **查看菜单权限**: 观察左侧菜单栏会随角色变化。例如，医生可以看到病历表，而收费员只能看到账单相关表。
3.  **数据读写测试**:
    - 选择具有写权限的角色（如 `Super Admin` 或对应业务角色）。
    - 尝试修改一条数据（如果有 `✏️` 图标）。
    - 尝试插入数据（如果有插入权限）。
4.  **存储过程调用**:
    - 点击顶部的 **"Routine 过程/函数"** 链接。
    - 选择一个存储过程（如 `register_patient`）。
    - 点击 **"自动预填参数"**，然后点击 **"执行"**，观察返回结果。

---

## 🛠️ 常见问题 (Troubleshooting)

- **报错 `Access denied for user 'root'@'localhost' to database 'hospital_test'`**:
  - 检查 `.env` 文件中的密码是否正确。

- **报错 `ROLE ... is not granted`**:
  - 请务必执行 **步骤 2.3**，将所有业务角色授予给 `DB_USER` 配置的用户。

- **报错 `Unknown database 'hospital_test'`**:
  - 请确保已执行 **步骤 2.2** 中的创建数据库命令。

- **前端显示“加载失败”**:
  - 检查后端控制台是否有报错日志。
  - 确保后端服务正在运行且端口未被占用。

## 📚 开发说明

- **后端**: 修改 `backend/src` 下的代码后，如果是使用 `npm run dev` 启动（需安装 nodemon），服务会自动重启。
- **前端**: 修改 `frontend/` 下的文件后，刷新浏览器即可看到效果。
