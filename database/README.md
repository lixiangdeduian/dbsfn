# Hospital Management System (MySQL) SQL Scripts

本目录是 “Hospital Management System” 的数据库设计 SQL 脚本（MySQL 9.x 测试通过）。已将原来的大 SQL 文件按模块拆分到不同文件夹中；根目录下的 `schema.sql` / `triggers.sql` / `seed.sql` / `security.sql` 作为入口脚本，通过 `SOURCE` 顺序执行拆分后的文件，逻辑不变。

## 目录结构

- `schema.sql`：入口脚本（会 `\.` `sql/schema/*`）
- `triggers.sql`：入口脚本（会 `\.` `sql/triggers/*`）
- `seed.sql`：入口脚本（会 `\.` `sql/seed/*`，会 TRUNCATE 并生成大量数据）
- `security.sql`：入口脚本（会 `\.` `sql/security/*`）
- `sql/`：拆分后的脚本
  - `sql/schema/`：库/表结构
  - `sql/triggers/`：触发器
  - `sql/seed/`：初始化数据过程与执行
  - `sql/security/`：角色/视图/授权
- `legacy/`：拆分前的原始整文件备份（仅用于对照）

## 执行顺序

注意：入口脚本依赖相对路径 `\.`（等价于 `SOURCE`），请在本目录下执行（即当前工作目录是 `database/`）。
如果你的 `mysql` 客户端启用了 `--disable-named-commands`（或在 `~/.my.cnf` 里配置了同名选项），`SOURCE` 会被当成 SQL 发给服务端并报语法错；本项目入口脚本已改用 `\.` 以兼容该配置。

```bash
# MySQL 9.x 在非交互模式下默认不处理本地命令（如 `\.` / `SOURCE`），需要显式开启
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
# 可选：会清空并重新生成大量业务数据
mysql --commands -u root -p < seed.sql
mysql --commands -u root -p < security.sql
mysql --commands -u root -p < routines.sql
# 若需要授予各角色执行存储过程（EXECUTE）权限，请在 routines.sql 之后执行：
mysql --commands -u root -p < sql/security/5_grants_routines.sql
```

## 快速核对（在 mysql 客户端内）

```sql
USE hospital_test;
SHOW TABLES;
SHOW TRIGGERS;
SHOW FULL TABLES WHERE Table_type='VIEW';
```
