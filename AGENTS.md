# Repository Guidelines

## Project Structure & Module Organization
- `backend/`: Express + Sequelize API (`src/server.js` serves `/api` and static frontend). Config loads from `backend/.env` via `src/config.js`.
- `frontend/`: Static dashboard (`index.html`, `script.js`, `styles.css`), bundled as-is and served by the backend.
- `database/`: MySQL scripts; execute `schema.sql`, `triggers.sql`, `seed.sql`, `security.sql`, `routines.sql` from this directory. Role/menu definitions live in `database/sql/security/4_grants.sql`.

## Build, Test, and Development Commands
- Install deps: `cd backend && npm install`.
- Dev server with reload: `npm run dev` (nodemon; requires a configured MySQL instance).
- Start server: `npm start` (serves API + frontend on `PORT`, default 3000).
- Initialize DB (run from `database/`):  
  `mysql --commands -u <user> -p < schema.sql` → `triggers.sql` → `seed.sql` → `security.sql` → `routines.sql`.

## Coding Style & Naming Conventions
- JavaScript uses CommonJS, 2-space indentation, semicolons, async/await; keep handlers small and rely on `sequelize.query` with parameter replacements.
- Keep API contracts stable (`/api/roles`, `/api/menu`, `/api/objects/:name`). Sanitize identifiers before using them in SQL; follow existing `sanitizeIdentifier` pattern.
- Place new backend logic in `backend/src/`; keep frontend changes vanilla (no build step).
- Environment: add `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `PORT` in `backend/.env` (do not commit secrets).

## Testing Guidelines
- No automated tests; validate manually:
  - `/api/roles` returns role list including `super_admin`.
  - Role-driven menus match `4_grants.sql` and show correct `R/RW` badges.
  - Switching roles in the UI updates visible objects and write badge; RW objects allow row selection/edit.
  - Ensure DB user is granted all roles and can `SET ROLE`.

## Commit & Pull Request Guidelines
- Recent history uses short, imperative-style Chinese summaries (e.g., “初步完成前后端搭建”); keep messages concise and scoped (prefix with area like `backend:`/`frontend:` when helpful).
- Before opening a PR, verify the backend starts, the DB scripts still apply cleanly, and the UI can load data for multiple roles. Mention any schema/script touchpoints and required env vars.

## Security & Configuration Tips
- Least-privilege DB users must still have the necessary roles granted; errors often stem from missing `GRANT role_* ...` or absent `SET DEFAULT ROLE`.
- Never log DB credentials; prefer `.env` and keep it out of version control. Limit query logging unless debugging.***
