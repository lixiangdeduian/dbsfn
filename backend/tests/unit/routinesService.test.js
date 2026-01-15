const { listRoutines, executeRoutine } = require('../../src/routinesService');
const sequelize = require('../../src/db');
const dbRole = require('../../src/dbRole');

jest.mock('../../src/db', () => ({
  transaction: jest.fn(cb => cb('mockTransaction')),
  query: jest.fn()
}));

jest.mock('../../src/dbRole', () => ({
  setRole: jest.fn(),
  sanitizeIdentifier: jest.fn(name => name)
}));

describe('routinesService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('listRoutines returns array of routines', async () => {
    const routines = await listRoutines();
    expect(Array.isArray(routines)).toBe(true);
    expect(routines.length).toBeGreaterThan(0);
    expect(routines[0]).toHaveProperty('name');
  });

  test('executeRoutine calls stored procedure', async () => {
    // Mock sequelize.query for the CALL
    sequelize.query.mockResolvedValueOnce([]); // CALL result
    // Mock sequelize.query for the SELECT outputs
    sequelize.query.mockResolvedValueOnce([{ o_patient_id: 123, o_patient_no: 'P001' }]); // SELECT outputs

    const result = await executeRoutine('sp_patient_create', 'super_admin', {
      p_patient_name: 'Test Patient',
      p_gender: 'M'
    });
    
    // Check that setRole was called
    expect(dbRole.setRole).toHaveBeenCalledWith('super_admin', 'mockTransaction', null);

    // Check query calls
    expect(sequelize.query).toHaveBeenCalledTimes(2);
    const callSql = sequelize.query.mock.calls[0][0];
    expect(callSql).toMatch(/CALL `sp_patient_create`/);
    
    expect(result.outputs).toHaveProperty('o_patient_id', 123);
  });
  
  test('executeRoutine throws on unknown routine', async () => {
    await expect(executeRoutine('unknown_sp', 'super_admin', {}))
      .rejects.toThrow('未知的例程名称');
  });

  test('executeRoutine validates required params', async () => {
    // p_patient_name is required for sp_patient_create
    await expect(executeRoutine('sp_patient_create', 'super_admin', {}))
      .rejects.toThrow(); // Should throw error about missing param
  });
});
