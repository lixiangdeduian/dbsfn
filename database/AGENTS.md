# Repository Guidelines

This repository contains a MySQL-based “Hospital Management System” database design delivered as executable SQL scripts. The top-level `*.sql` files are **entry scripts** that `\.` (SOURCE) the split modules under `sql/`.

## Project Structure & Module Organization

- `schema.sql`: database + table/constraint definitions (sources `sql/schema/*`).
- `triggers.sql`: trigger definitions (sources `sql/triggers/*`).
- `seed.sql`: optional data generator (sources `sql/seed/*`; **truncates** and re-populates data).
- `security.sql`: roles, views, grants (sources `sql/security/*`).
- `routines.sql`: stored procedures/functions (sources `sql/routines/*`).
- `sql/`: split modules, organized by domain; files are prefixed with numbers to enforce execution order (e.g., `sql/schema/0_init.sql`).

## Build, Test, and Development Commands

Run from this directory (`database/`) so relative `\.` paths resolve correctly.

```bash
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
mysql --commands -u root -p < seed.sql      # optional, destructive
mysql --commands -u root -p < security.sql
mysql --commands -u root -p < routines.sql
# optional: grant roles EXECUTE on procedures
mysql --commands -u root -p < sql/security/5_grants_routines.sql
```

Quick sanity checks (inside `mysql`):

```sql
USE hospital_test;
SHOW TABLES;
SHOW TRIGGERS;
SHOW FULL TABLES WHERE Table_type='VIEW';
```

## Coding Style & Naming Conventions

- SQL formatting: 2-space indentation; uppercase keywords (`CREATE TABLE`, `FOREIGN KEY`).
- Naming: lowercase `snake_case` for tables/columns; indexes/constraints use `ix_*`, `uq_*`, `fk_*`, `ck_*`; triggers use `trg_*`.
- Prefer additive migrations: keep files modular and update the relevant `sql/<module>/` file rather than editing entry scripts.

## Testing Guidelines

There is no automated test harness in this repo. Validate changes by executing entry scripts in order and running targeted queries for the affected tables/triggers (e.g., insert/update flows that should `SIGNAL` on invalid states).

## Commit & Pull Request Guidelines

- Commits in history use short, descriptive messages (often Chinese) that state what changed (e.g., “拆分数据库文件”, “添加游标和一些过程”).
- Keep PRs focused: describe the business rule changed, list affected scripts (e.g., `sql/triggers/5_amount_calc.sql`), and include the exact verification commands you ran.
