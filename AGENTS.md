# Repository Guidelines

## Project Structure & Module Organization

- `database/`: MySQL scripts for the Hospital Management System.
  - Entry points: `database/schema.sql`, `database/triggers.sql`, `database/routines.sql`, `database/seed.sql`, `database/security.sql`
  - Modular scripts: `database/sql/{schema,triggers,routines,seed,security}/` (executed in numeric file order, e.g. `0_preamble.sql`, `1_*.sql`)
  - Notes and usage: `database/README.md`
  - Design checklist / assignment notes: `database/task.md`

## Build, Test, and Development Commands

Run commands from `database/` (entry scripts rely on relative `\.` includes).

```bash
cd database
mysql --commands -u root -p < schema.sql
mysql --commands -u root -p < triggers.sql
mysql --commands -u root -p < routines.sql
mysql --commands -u root -p < security.sql
# Optional (destructive): truncates and regenerates sample data
mysql --commands -u root -p < seed.sql
```

## Coding Style & Naming Conventions

- SQL formatting: 2-space indentation inside `BEGIN ... END`; keep statements one-per-line where practical.
- Naming: `lower_snake_case` for tables/columns; triggers use `trg_<table>_<timing>_<purpose>` (e.g. `trg_patient_bi_audit`).
- Ordering: new module files should use the existing numeric prefix pattern to preserve deterministic execution.

## Testing Guidelines

There is no automated test runner. Use lightweight smoke checks after changes:

```sql
USE hospital_test;
SHOW TABLES;
SHOW TRIGGERS;
SHOW FULL TABLES WHERE Table_type='VIEW';
```

If you change security/roles, validate permissions with a least-privilege account before merging.

## Commit & Pull Request Guidelines

- Commits: keep messages short and action-oriented; include the area touched (e.g., “triggers: enforce bed overlap rule”).
- PRs: describe the business rule/constraint added, list entry scripts affected, and include the exact `mysql --commands ... < ...` sequence used to verify.

## Security & Data Safety

- Treat `seed.sql` as destructive (it truncates business tables); never run it against non-dev databases.
- Keep grants in `database/sql/security/` and prefer granting through views for sensitive data.
