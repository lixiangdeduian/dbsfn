# Hospital Admin Console

基于 `hospital_test` 数据库的后台管理界面与 API。前端无登录页，访问服务根路径即可进入；角色切换由前端/请求参数控制，并通过 MySQL `SET ROLE` 模拟权限。

## 目录结构
- `backend/`: Express + Sequelize API，提供角色/菜单/数据接口并服务前端静态文件。
- `frontend/`: 纯静态界面（HTML/CSS/JS），从 `/api` 拉取数据。
- `database/`: 已有的数据库脚本（未改动）。

## 运行步骤
1. 初始化数据库（需本地 MySQL 8+）：
   - 创建库 `hospital_test`，依次执行 `database/schema.sql` → `triggers.sql` → `routines.sql` → `security.sql` → `seed.sql`。
2. 配置后端环境变量：
   - 复制 `backend/.env.example` 为 `backend/.env`，填写 `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD`（需要有 `SET ROLE` 权限）和 `DB_NAME`。
3. 安装依赖并启动：
   ```bash
   cd backend
   npm install
   npm run dev   # 或 npm start
   ```
4. 打开浏览器访问 `http://localhost:3000`（默认端口可在 `.env` 的 `PORT` 调整）。

### 角色授权提示
后端会对每个请求执行 `SET ROLE`，请确保连接的 DB 用户已被授予这些角色，否则会出现 “is not granted” 报错。示例（如使用 root/localhost，请按需替换用户名/主机）：
```sql
GRANT role_admin, role_reception, role_doctor, role_nurse, role_pharmacist, role_lab_tech, role_cashier, role_patient TO 'root'@'localhost';
SET DEFAULT ROLE ALL TO 'root'@'localhost';
FLUSH PRIVILEGES;
```

## API 快照
- `GET /api/roles`：返回角色列表（包含 `super_admin`）。
- `GET /api/menu?role=role_doctor`：返回该角色可见的视图/表及 R/RW 标识。
- `GET /api/objects/{objectName}?role=role_doctor&page=1&pageSize=20`：返回列信息与分页数据，自动按角色执行 `SET ROLE`。

## 手动验收要点
- 切换不同角色（如 `role_reception` vs `role_doctor`），左侧菜单对象集合应随 `4_grants.sql` 变化。
- 同一对象在不同角色下的 `R/RW` 标识正确，RW 对象顶部会显示 ✏️ 写权限徽标。
- 选择 `super_admin` 时能看到所有表与视图并具备写权限标识。
