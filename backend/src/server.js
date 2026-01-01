const express = require('express');
const cors = require('cors');
const path = require('path');
const { QueryTypes } = require('sequelize');
const sequelize = require('./db');
const config = require('./config');
const {
  listRoles,
  buildMenu,
  isObjectAllowed,
  accessModeFor,
  getObjectType,
  loadSchemaObjects
} = require('./schemaService');
const { resolveDisplayName } = require('./nameMap');

const app = express();
app.use(cors());
app.use(express.json());

function sanitizeIdentifier(name) {
  if (!name || !/^[a-zA-Z0-9_]+$/.test(name)) return null;
  return name;
}

async function displayNameFor(objectName) {
  const all = await loadSchemaObjects();
  const meta = all.find((o) => o.name === objectName);
  return resolveDisplayName(objectName, meta ? meta.comment : '');
}

async function setRole(roleName, transaction) {
  const role = roleName === 'super_admin' ? 'role_admin' : roleName;
  const safeRole = sanitizeIdentifier(role);
  if (!safeRole) {
    throw new Error('Invalid role name');
  }
  try {
    await sequelize.query(`SET ROLE ${safeRole}`, { transaction });
  } catch (err) {
    const hint = `DB 用户需要被授予所需角色，例如: GRANT role_admin, role_reception, role_doctor, role_nurse, role_pharmacist, role_lab_tech, role_cashier, role_patient TO '${config.dbUser}'@'${config.dbHost}'; SET DEFAULT ROLE ALL TO '${config.dbUser}'@'${config.dbHost}';`;
    throw new Error(`${err.message}. ${hint}`);
  }
}

app.get('/api/roles', async (_req, res) => {
  try {
    const roles = listRoles();
    res.json({ roles });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put('/api/objects/:name', async (req, res) => {
  const role = req.query.role || 'super_admin';
  const objectName = sanitizeIdentifier(req.params.name);
  if (!objectName) {
    return res.status(400).json({ message: 'Invalid object name' });
  }
  const { data, where } = req.body || {};
  if (!data || typeof data !== 'object' || !where || typeof where !== 'object') {
    return res.status(400).json({ message: 'Request body must include data and where' });
  }

  try {
    const allowed = await isObjectAllowed(role, objectName);
    if (!allowed) {
      return res.status(403).json({ message: 'Object not permitted for this role' });
    }
    const accessMode = await accessModeFor(role, objectName);
    if (accessMode !== 'RW') {
      return res.status(403).json({ message: 'Object is read-only for this role' });
    }

    await sequelize.transaction(async (transaction) => {
      await setRole(role, transaction);

      const columns = await sequelize.query(
        `SELECT column_name AS name
         FROM information_schema.columns
         WHERE table_schema = :schema AND table_name = :table`,
        {
          replacements: { schema: config.dbName, table: objectName },
          type: QueryTypes.SELECT,
          transaction
        }
      );
      const allowedColumns = new Set(columns.map((c) => c.name));

      const dataEntries = Object.entries(data).filter(([k]) => allowedColumns.has(k));
      const whereEntries = Object.entries(where).filter(([k]) => allowedColumns.has(k));

      if (!dataEntries.length) {
        throw new Error('No valid columns to update');
      }
      if (!whereEntries.length) {
        throw new Error('No valid conditions supplied');
      }

      const setClause = dataEntries
        .map(([col], idx) => `\`${col}\` = :set_${idx}`)
        .join(', ');
      const whereClause = whereEntries
        .map(([col], idx) => `\`${col}\` = :where_${idx}`)
        .join(' AND ');

      const replacements = {};
      dataEntries.forEach(([col, val], idx) => {
        replacements[`set_${idx}`] = val;
      });
      whereEntries.forEach(([col, val], idx) => {
        replacements[`where_${idx}`] = val;
      });

      const [result] = await sequelize.query(
        `UPDATE \`${objectName}\` SET ${setClause} WHERE ${whereClause} LIMIT 1`,
        {
          replacements,
          transaction
        }
      );

      res.json({ updated: result?.affectedRows ?? 0 });
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.get('/api/menu', async (req, res) => {
  const role = req.query.role || 'super_admin';
  try {
    const items = await buildMenu(role);
    res.json({ role, items });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/objects/:name', async (req, res) => {
  const role = req.query.role || 'super_admin';
  const objectName = sanitizeIdentifier(req.params.name);
  const page = Number(req.query.page || 1);
  const pageSize = Number(req.query.pageSize || 20);

  if (!objectName) {
    return res.status(400).json({ message: 'Invalid object name' });
  }

  try {
    const allowed = await isObjectAllowed(role, objectName);
    if (!allowed) {
      return res.status(403).json({ message: 'Object not permitted for this role' });
    }
    const objectType = await getObjectType(objectName);
    if (!objectType) {
      return res.status(404).json({ message: 'Object not found in schema' });
    }
    const displayName = await displayNameFor(objectName);

    await sequelize.transaction(async (transaction) => {
      await setRole(role, transaction);

      const columns = await sequelize.query(
        `SELECT column_name AS name, data_type AS dataType, is_nullable AS isNullable, column_key AS columnKey, column_comment AS columnComment
         FROM information_schema.columns
         WHERE table_schema = :schema AND table_name = :table
        ORDER BY ordinal_position`,
        {
          replacements: { schema: config.dbName, table: objectName },
          type: QueryTypes.SELECT,
          transaction
        }
      );

      const rows = await sequelize.query(
        `SELECT * FROM \`${objectName}\` LIMIT :limit OFFSET :offset`,
        {
          replacements: { limit: pageSize, offset: (page - 1) * pageSize },
          type: QueryTypes.SELECT,
          transaction
        }
      );
      let total = null;
      try {
        const countRows = await sequelize.query(`SELECT COUNT(*) AS total FROM \`${objectName}\``, {
          type: QueryTypes.SELECT,
          transaction
        });
        total = countRows?.[0]?.total ?? null;
      } catch (err) {
        total = null;
      }

      const accessMode = await accessModeFor(role, objectName);

      res.json({
        role,
        object: {
          name: objectName,
          type: objectType,
          displayName,
          accessMode,
          writable: accessMode === 'RW'
        },
        columns,
        rows,
        pagination: {
          page,
          pageSize,
          total
        }
      });
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.use(
  express.static(path.resolve(__dirname, '../../frontend'), {
    extensions: ['html', 'htm']
  })
);

app.get('*', (_req, res) => {
  res.sendFile(path.resolve(__dirname, '../../frontend/index.html'));
});

async function bootstrap() {
  try {
    await sequelize.authenticate();
    await loadSchemaObjects();
    app.listen(config.port, () => {
      console.log(`Server running at http://localhost:${config.port}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

bootstrap();
