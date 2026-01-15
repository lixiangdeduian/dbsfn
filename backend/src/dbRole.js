const sequelize = require('./db');
const config = require('./config');

function sanitizeIdentifier(name) {
  if (!name || !/^[a-zA-Z0-9_]+$/.test(name)) return null;
  return name;
}

async function setRole(roleName, transaction, username = null) {
  const role = roleName === 'super_admin' ? 'role_admin' : roleName;
  const safeRole = sanitizeIdentifier(role);
  if (!safeRole) {
    throw new Error('Invalid role name');
  }
  try {
    await sequelize.query(`SET ROLE ${safeRole}`, { transaction });
    if (username) {
      await sequelize.query('SET @current_username = :username', {
        replacements: { username },
        transaction
      });
    } else {
      await sequelize.query('SET @current_username = NULL', { transaction });
    }
  } catch (err) {
    const hint = `DB 用户需要被授予所需角色，例如: GRANT role_admin, role_reception, role_doctor, role_nurse, role_pharmacist, role_lab_tech, role_cashier, role_patient TO '${config.dbUser}'@'${config.dbHost}'; SET DEFAULT ROLE ALL TO '${config.dbUser}'@'${config.dbHost}';`;
    throw new Error(`${err.message}. ${hint}`);
  }
}

module.exports = {
  sanitizeIdentifier,
  setRole
};
