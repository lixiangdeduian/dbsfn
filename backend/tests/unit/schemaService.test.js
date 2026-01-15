const { buildMenu } = require('../../src/schemaService');
const sequelize = require('../../src/db');
const privileges = require('../../src/privileges');

jest.mock('../../src/db', () => ({
  query: jest.fn()
}));

jest.mock('../../src/privileges', () => ({
  listRoles: jest.fn(),
  roleHasAll: jest.fn(),
  getPrivilegesForRole: jest.fn(),
  isWritablePrivilege: jest.fn(),
  hasInsertPrivilege: jest.fn()
}));

describe('schemaService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    sequelize.query.mockResolvedValue([
      { name: 'table1', type: 'BASE TABLE', comment: 'Table 1' },
      { name: 'view1', type: 'VIEW', comment: 'View 1' }
    ]);
  });

  test('buildMenu for super_admin returns all objects RW', async () => {
    const menu = await buildMenu('super_admin');
    expect(menu).toHaveLength(2);
    expect(menu[0].accessMode).toBe('RW');
    expect(menu[1].accessMode).toBe('RW');
  });

  test('buildMenu for restricted role returns only allowed objects', async () => {
    privileges.roleHasAll.mockReturnValue(false);
    privileges.getPrivilegesForRole.mockReturnValue({
      'table1': ['SELECT']
    });
    privileges.isWritablePrivilege.mockImplementation(privs => privs.includes('INSERT'));

    const menu = await buildMenu('restricted_role');
    expect(menu).toHaveLength(1);
    expect(menu[0].name).toBe('table1');
    expect(menu[0].accessMode).toBe('R');
  });
});
