const { QueryTypes } = require('sequelize');
const sequelize = require('./db');
const config = require('./config');
const {
  listRoles,
  roleHasAll,
  getPrivilegesForRole,
  isWritablePrivilege,
  hasInsertPrivilege
} = require('./privileges');
const { resolveDisplayName } = require('./nameMap');

let cachedObjects = null;

async function loadSchemaObjects() {
  if (cachedObjects) return cachedObjects;
  const rows = await sequelize.query(
    `SELECT table_name AS name, table_type AS type, table_comment AS comment
     FROM information_schema.tables
     WHERE table_schema = :schema`,
    {
      replacements: { schema: config.dbName },
      type: QueryTypes.SELECT
    }
  );
  cachedObjects = rows.map((r) => ({
    name: r.name,
    type: r.type === 'VIEW' ? 'VIEW' : 'BASE TABLE',
    comment: r.comment || ''
  }));
  return cachedObjects;
}

async function getObjectType(objectName) {
  const objects = await loadSchemaObjects();
  const found = objects.find((o) => o.name === objectName);
  return found ? found.type : null;
}

function normalizeRole(role) {
  return role && role.trim() ? role.trim() : 'super_admin';
}

function normalizeObjectName(name) {
  return name && name.trim() ? name.trim() : '';
}

async function buildMenu(roleName) {
  const role = normalizeRole(roleName);
  const allObjects = await loadSchemaObjects();

  if (role === 'super_admin' || roleHasAll(role)) {
    return allObjects
      .map((obj) => ({
        name: obj.name,
        type: obj.type,
        displayName: resolveDisplayName(obj.name, obj.comment),
        accessMode: 'RW'
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  const privileges = getPrivilegesForRole(role);
  const menuItems = [];
  for (const [objectName, privs] of Object.entries(privileges)) {
    const meta = allObjects.find((o) => o.name === objectName) || {};
    const type = meta.type || 'BASE TABLE';
    const displayName = resolveDisplayName(objectName, meta.comment);
    const accessMode = isWritablePrivilege(privs) ? 'RW' : 'R';
    menuItems.push({ name: objectName, type, accessMode, displayName });
  }
  return menuItems.sort((a, b) => a.name.localeCompare(b.name));
}

async function isObjectAllowed(roleName, objectName) {
  const role = normalizeRole(roleName);
  const name = normalizeObjectName(objectName);
  if (!name) return false;
  if (role === 'super_admin' || roleHasAll(role)) return true;
  const privileges = getPrivilegesForRole(role);
  return Boolean(privileges[name]);
}

async function accessModeFor(roleName, objectName) {
  const role = normalizeRole(roleName);
  if (role === 'super_admin' || roleHasAll(role)) return 'RW';
  const privileges = getPrivilegesForRole(role);
  const privs = privileges[objectName] || [];
  return isWritablePrivilege(privs) ? 'RW' : 'R';
}

async function canInsert(roleName, objectName) {
  const role = normalizeRole(roleName);
  if (role === 'super_admin' || roleHasAll(role)) return true;
  const privileges = getPrivilegesForRole(role);
  const privs = privileges[objectName] || [];
  return hasInsertPrivilege(privs);
}

module.exports = {
  listRoles,
  buildMenu,
  isObjectAllowed,
  accessModeFor,
  getObjectType,
  loadSchemaObjects,
  canInsert
};
