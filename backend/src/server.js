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
  loadSchemaObjects,
  canInsert
} = require('./schemaService');
const { resolveDisplayName } = require('./nameMap');
const { sanitizeIdentifier, setRole } = require('./dbRole');
const { listRoutines, buildRoutineExample, executeRoutine } = require('./routinesService');

const app = express();
app.use(cors());
app.use(express.json());

function nowStrings(offsetMinutes = 0) {
  const d = new Date(Date.now() + offsetMinutes * 60000);
  const pad = (n) => (n < 10 ? `0${n}` : `${n}`);
  const dateStr = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  const timeStr = `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  const dateTimeStr = `${dateStr} ${timeStr}`;
  return { dateStr, timeStr, dateTimeStr };
}

async function displayNameFor(objectName) {
  const all = await loadSchemaObjects();
  const meta = all.find((o) => o.name === objectName);
  return resolveDisplayName(objectName, meta ? meta.comment : '');
}

app.get('/api/roles', async (_req, res) => {
  try {
    const roles = listRoles();
    res.json({ roles });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/routines', async (_req, res) => {
  try {
    const routines = await listRoutines();
    res.json({ routines });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/routines/:name/example', async (req, res) => {
  const role = req.query.role || 'super_admin';
  try {
    const data = await buildRoutineExample(req.params.name, role);
    res.json({ role, routine: req.params.name, params: data.params });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.post('/api/routines/:name/execute', async (req, res) => {
  const role = req.query.role || 'super_admin';
  const { params } = req.body || {};
  try {
    const data = await executeRoutine(req.params.name, role, params || {});
    res.json({ role, routine: req.params.name, ...data });
  } catch (err) {
    res.status(400).json({ message: err.message });
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
        `SELECT column_name AS name, data_type AS dataType, is_nullable AS isNullable, column_key AS columnKey, column_comment AS columnComment,
                column_default AS columnDefault, character_maximum_length AS maxLength, column_type AS columnType, extra
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
      const insertable = await canInsert(role, objectName);

      res.json({
        role,
        object: {
          name: objectName,
          type: objectType,
          displayName,
          accessMode,
          writable: accessMode === 'RW',
          insertable
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

async function fetchForeignKeys(objectName, transaction) {
  const fks = await sequelize.query(
    `SELECT column_name AS columnName, referenced_table_name AS refTable, referenced_column_name AS refColumn
     FROM information_schema.key_column_usage
     WHERE table_schema = :schema AND table_name = :table AND referenced_table_name IS NOT NULL`,
    {
      replacements: { schema: config.dbName, table: objectName },
      type: QueryTypes.SELECT,
      transaction
    }
  );
  const map = {};
  fks.forEach((fk) => {
    map[fk.columnName] = { table: fk.refTable, column: fk.refColumn };
  });
  return map;
}

async function pickReferencedValue(refTable, refColumn, transaction) {
  const safeTable = sanitizeIdentifier(refTable);
  const safeColumn = sanitizeIdentifier(refColumn);
  if (!safeTable || !safeColumn) return null;
  try {
    const rows = await sequelize.query(
      `SELECT \`${safeColumn}\` AS val FROM \`${safeTable}\` ORDER BY RAND() LIMIT 1`,
      { type: QueryTypes.SELECT, transaction }
    );
    return rows?.[0]?.val ?? null;
  } catch (_err) {
    return null;
  }
}

async function pickAvailableBed(startAt, endAt, transaction) {
  const rows = await sequelize.query(
    `SELECT b.bed_id AS bedId
     FROM bed b
     WHERE NOT EXISTS (
       SELECT 1 FROM bed_assignment ba
       WHERE ba.bed_id = b.bed_id
         AND COALESCE(ba.end_at, '9999-12-31 23:59:59.999') > :startAt
         AND :endAt > ba.start_at
     )
     LIMIT 1`,
    {
      replacements: { startAt, endAt },
      type: QueryTypes.SELECT,
      transaction
    }
  );
  return rows?.[0]?.bedId ?? null;
}

async function pickPendingLabOrderItem(transaction) {
  const rows = await sequelize.query(
    `SELECT loi.lab_order_item_id AS itemId
     FROM lab_order_item loi
     JOIN lab_order lo ON lo.lab_order_id = loi.lab_order_id
     LEFT JOIN lab_result lr ON lr.lab_order_item_id = loi.lab_order_item_id
     WHERE lr.lab_result_id IS NULL
       AND lo.status <> 'CANCELLED'
     ORDER BY RAND()
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.itemId ?? null;
}

async function pickActiveStaff(transaction) {
  const rows = await sequelize.query(
    `SELECT staff_id AS staffId FROM staff WHERE is_active = 1 ORDER BY RAND() LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.staffId ?? null;
}

async function fetchUniqueColumns(table, transaction) {
  const rows = await sequelize.query(
    `SELECT kcu.column_name AS columnName
     FROM information_schema.table_constraints tc
     JOIN information_schema.key_column_usage kcu
       ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
      AND tc.table_name = kcu.table_name
     WHERE tc.table_schema = :schema
       AND tc.table_name = :table
       AND tc.constraint_type = 'UNIQUE'
       AND kcu.ordinal_position IS NOT NULL`,
    {
      replacements: { schema: config.dbName, table },
      type: QueryTypes.SELECT,
      transaction
    }
  );
  return new Set(rows.map((r) => r.columnName));
}

async function fetchSampleRow(table, transaction) {
  const safeTable = sanitizeIdentifier(table);
  if (!safeTable) return null;
  const rows = await sequelize.query(`SELECT * FROM \`${safeTable}\` LIMIT 1`, {
    type: QueryTypes.SELECT,
    transaction
  });
  return rows?.[0] || null;
}

async function buildInsertExample(objectName, transaction) {
  const columns = await sequelize.query(
    `SELECT column_name AS name, data_type AS dataType, is_nullable AS isNullable, column_key AS columnKey, column_comment AS columnComment,
            column_default AS columnDefault, character_maximum_length AS maxLength, column_type AS columnType, extra
     FROM information_schema.columns
     WHERE table_schema = :schema AND table_name = :table
     ORDER BY ordinal_position`,
    {
      replacements: { schema: config.dbName, table: objectName },
      type: QueryTypes.SELECT,
      transaction
    }
  );
  const fkMap = await fetchForeignKeys(objectName, transaction);
  const uniqueCols = await fetchUniqueColumns(objectName, transaction);
  const sampleRow = await fetchSampleRow(objectName, transaction);
  const example = {};
  const { dateStr, timeStr, dateTimeStr } = nowStrings(60);
  const uniqueSuffix = Date.now().toString(36);

  // Special handling for time windows
  const startAtDate = new Date(Date.now() + 90 * 60000);
  const endAtDate = new Date(startAtDate.getTime() + 6 * 60 * 60000);
  const formatDateTime = (d) => {
    const pad = (n) => (n < 10 ? `0${n}` : `${n}`);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(
      d.getMinutes()
    )}:${pad(d.getSeconds())}`;
  };
  const startAt = formatDateTime(startAtDate);
  const endAt = formatDateTime(endAtDate);

  for (const col of columns) {
    const name = col.name;
    const type = (col.dataType || '').toLowerCase();
    const comment = (col.columnComment || '').toLowerCase();
    const autoIncrement = (col.extra || '').toLowerCase().includes('auto_increment');
    const maxLength = col.maxLength || 128;
    const isUnique = uniqueCols.has(name);
    const enumValues =
      col.columnType && col.columnType.toLowerCase().startsWith('enum(')
        ? col.columnType
            .slice(col.columnType.indexOf('(') + 1, col.columnType.lastIndexOf(')'))
            .split(',')
            .map((v) => v.trim().replace(/^'/, '').replace(/'$/, ''))
        : null;

    if (autoIncrement) {
      continue;
    }

    if (objectName === 'lab_result') {
      if (name === 'lab_order_item_id') {
        const itemId = await pickPendingLabOrderItem(transaction);
        if (!itemId) {
          throw new Error('暂无未录入结果的检验明细可用，请先创建检验单或执行准备结果');
        }
        example[name] = itemId;
        continue;
      }
      if (name === 'result_flag') {
        example[name] = 'NORMAL';
        continue;
      }
      if (name === 'result_value') {
        example[name] = '5.6';
        continue;
      }
      if (name === 'result_text') {
        example[name] = '自动示例结果';
        continue;
      }
      if (name === 'result_at') {
        example[name] = dateTimeStr;
        continue;
      }
      if (name === 'technician_id') {
        example[name] = await pickActiveStaff(transaction);
        continue;
      }
    }

    if (objectName === 'bed_assignment') {
      if (name === 'start_at') {
        example[name] = startAt;
        continue;
      }
      if (name === 'end_at') {
        example[name] = endAt;
        continue;
      }
      if (name === 'bed_id') {
        const bedId = await pickAvailableBed(startAt, endAt, transaction);
        if (bedId !== null && bedId !== undefined) {
          example[name] = bedId;
          continue;
        }
      }
    }

    if (fkMap[name]) {
      const refVal = await pickReferencedValue(fkMap[name].table, fkMap[name].column, transaction);
      example[name] = refVal !== null && refVal !== undefined ? refVal : sampleRow?.[name] ?? null;
      continue;
    }

    if (type.includes('datetime') || type.includes('timestamp')) {
      example[name] = sampleRow?.[name] || dateTimeStr;
      continue;
    }
    if (type === 'date') {
      example[name] = sampleRow?.[name] || dateStr;
      continue;
    }
    if (type === 'time') {
      example[name] = sampleRow?.[name] || timeStr;
      continue;
    }

    if (comment.includes('日期') || comment.includes('时间')) {
      example[name] = sampleRow?.[name] || dateTimeStr;
      continue;
    }

    if (enumValues && enumValues.length) {
      const defaultEnum = col.columnDefault || enumValues[0] || null;
      example[name] = sampleRow?.[name] || defaultEnum;
      continue;
    }

    if (type.includes('int') || type.includes('decimal') || type.includes('numeric') || type.includes('float')) {
      const baseNumber =
        sampleRow && sampleRow[name] !== undefined && sampleRow[name] !== null
          ? sampleRow[name]
          : Number(Date.now() % 1000000);
      example[name] = isUnique ? baseNumber + Math.floor(Math.random() * 1000) + 1 : baseNumber;
      continue;
    }

    const baseVal =
      sampleRow && sampleRow[name] !== undefined && sampleRow[name] !== null
        ? String(sampleRow[name])
        : col.columnDefault !== null && col.columnDefault !== undefined
        ? String(col.columnDefault)
        : `${name}_${uniqueSuffix}`;
    const finalVal = isUnique ? `${baseVal}_${uniqueSuffix}` : baseVal;
    example[name] = finalVal.slice(0, maxLength);
  }

  return example;
}

app.get('/api/objects/:name/example', async (req, res) => {
  const role = req.query.role || 'super_admin';
  const objectName = sanitizeIdentifier(req.params.name);

  if (!objectName) {
    return res.status(400).json({ message: 'Invalid object name' });
  }

  try {
    const allowed = await isObjectAllowed(role, objectName);
    if (!allowed) {
      return res.status(403).json({ message: 'Object not permitted for this role' });
    }
    const insertable = await canInsert(role, objectName);
    if (!insertable) {
      return res.status(403).json({ message: 'Object is not insertable for this role' });
    }

    await sequelize.transaction(async (transaction) => {
      await setRole(role, transaction);
      const example = await buildInsertExample(objectName, transaction);
      res.json({ role, object: objectName, example });
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

app.post('/api/objects/:name', async (req, res) => {
  const role = req.query.role || 'super_admin';
  const objectName = sanitizeIdentifier(req.params.name);
  const { data } = req.body || {};

  if (!objectName) {
    return res.status(400).json({ message: 'Invalid object name' });
  }
  if (!data || typeof data !== 'object') {
    return res.status(400).json({ message: 'Request body must include data object' });
  }

  try {
    const allowed = await isObjectAllowed(role, objectName);
    if (!allowed) {
      return res.status(403).json({ message: 'Object not permitted for this role' });
    }
    const insertable = await canInsert(role, objectName);
    if (!insertable) {
      return res.status(403).json({ message: 'Object is not insertable for this role' });
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
      const entries = Object.entries(data).filter(([k]) => allowedColumns.has(k));
      if (!entries.length) {
        throw new Error('No valid columns to insert');
      }

      const colClause = entries.map(([col]) => `\`${col}\``).join(', ');
      const valuesClause = entries.map(([_col, _val], idx) => `:val_${idx}`).join(', ');
      const replacements = {};
      entries.forEach(([, val], idx) => {
        replacements[`val_${idx}`] = val;
      });

      const [result] = await sequelize.query(
        `INSERT INTO \`${objectName}\` (${colClause}) VALUES (${valuesClause})`,
        {
          replacements,
          transaction
        }
      );

      res.json({ inserted: result?.affectedRows ?? 0, insertId: result?.insertId });
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
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
