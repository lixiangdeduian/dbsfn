const fs = require('fs');
const path = require('path');

const GRANT_FILE = path.resolve(__dirname, '../../database/sql/security/4_grants.sql');

let parsed;

function ensureParsed() {
  if (parsed) return;
  const content = fs.readFileSync(GRANT_FILE, 'utf8');
  const lines = content.split('\n');
  const regex = /GRANT\s+(.+?)\s+ON\s+hospital_test\.([^\s]+)\s+TO\s+([a-zA-Z0-9_`]+)\s*;/i;
  const map = {};

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.toUpperCase().startsWith('GRANT')) continue;
    const match = trimmed.match(regex);
    if (!match) continue;
    const privileges = match[1].split(',').map((p) => p.trim().toUpperCase());
    const object = match[2].replace(/`/g, '');
    const role = match[3].replace(/`/g, '');
    if (!map[role]) {
      map[role] = { objects: {} };
    }
    if (object === '*') {
      map[role].all = true;
      continue;
    }
    map[role].objects[object] = privileges;
  }
  parsed = map;
}

function listRoles() {
  ensureParsed();
  const roles = new Set(Object.keys(parsed));
  roles.add('super_admin');
  return Array.from(roles);
}

function roleHasAll(roleName) {
  ensureParsed();
  const meta = parsed[roleName];
  return Boolean(meta && meta.all);
}

function getPrivilegesForRole(roleName) {
  ensureParsed();
  const meta = parsed[roleName];
  return meta ? meta.objects : {};
}

function isWritablePrivilege(privileges) {
  if (!privileges || !privileges.length) return false;
  if (privileges.includes('ALL PRIVILEGES') || privileges.includes('ALL')) return true;
  return ['INSERT', 'UPDATE', 'DELETE'].some((p) => privileges.includes(p));
}

module.exports = {
  listRoles,
  roleHasAll,
  getPrivilegesForRole,
  isWritablePrivilege
};
