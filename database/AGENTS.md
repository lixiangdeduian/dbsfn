# Repository Guidelines

## Project Structure & Module Organization

This repository is a MySQL-based “Hospital Management System” database design delivered as executable SQL scripts:

- `schema.sql`: database + table definitions, keys, constraints, indexes (run first).
- `triggers.sql`: audit/business triggers (run second).
- `security.sql`: roles, views, and grants (run last).
- `task.md`: requirements and design notes.

## Build, Test, and Development Commands

There is no application build; development is done by executing SQL against a local MySQL server (tested with MySQL 9.x).

- Create/refresh schema (idempotent objects use `IF NOT EXISTS`):
  - `mysql -u root -p < schema.sql`
- Add triggers:
  - `mysql -u root -p < triggers.sql`
- Add roles/views/grants:
  - `mysql -u root -p < security.sql`
- Quick sanity checks (run in `mysql`):
  - `USE hospital_mgmt; SHOW TABLES; SHOW TRIGGERS; SHOW FULL TABLES WHERE Table_type='VIEW';`

## Coding Style & Naming Conventions

- Naming: use lowercase `snake_case` for tables/columns; keep domain terms consistent with existing files.
- Keys/indexes: `pk` (implicit), `fk_*`, `uq_*`, `ix_*` prefixes as used in `schema.sql`.
- Views/roles/triggers: `v_*`, `role_*`, `trg_<table>_<timing>_<purpose>` (examples already in `security.sql`/`triggers.sql`).
- SQL style: 2-space indentation, one column per line, explicit `ENGINE=InnoDB`, and `utf8mb4` settings in `schema.sql`.

## Testing Guidelines

No automated test suite is included. Treat “tests” as executable verification:

- Scripts must be rerunnable: prefer `CREATE ... IF NOT EXISTS` and `DROP TRIGGER IF EXISTS` patterns.
- When changing constraints/triggers, validate with a minimal scenario (e.g., insert rows that should pass/fail) and ensure errors are informative.

## Commit & Pull Request Guidelines

No Git history is present in this folder. If you add VCS, use short, scoped messages like `schema: add bed_assignment constraints` and include:

- What changed (tables/columns/constraints/triggers/views).
- Execution order and any backward-incompatible changes.
- Example verification queries or repro steps.

