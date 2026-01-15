const request = require('supertest');

// Mock dependencies
jest.mock('../../src/db', () => {
  return {
    query: jest.fn(),
    authenticate: jest.fn().mockResolvedValue(),
    transaction: jest.fn(cb => cb('mockTransaction')),
    close: jest.fn()
  };
});

jest.mock('../../src/schemaService', () => ({
  listRoles: jest.fn(),
  buildMenu: jest.fn(),
  isObjectAllowed: jest.fn(),
  accessModeFor: jest.fn(),
  getObjectType: jest.fn(),
  loadSchemaObjects: jest.fn(),
  canInsert: jest.fn()
}));

jest.mock('../../src/routinesService', () => ({
  listRoutines: jest.fn(),
  buildRoutineExample: jest.fn(),
  executeRoutine: jest.fn()
}));

const app = require('../../src/server');
const schemaService = require('../../src/schemaService');
const routinesService = require('../../src/routinesService');

describe('API Integration Tests', () => {
  
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/roles', () => {
    test('returns roles list', async () => {
      schemaService.listRoles.mockReturnValue(['doctor', 'nurse']);
      
      const res = await request(app).get('/api/roles');
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ roles: ['doctor', 'nurse'] });
    });
  });

  describe('GET /api/routines', () => {
    test('returns routines list', async () => {
      routinesService.listRoutines.mockResolvedValue([{ name: 'sp_test' }]);
      
      const res = await request(app).get('/api/routines');
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ routines: [{ name: 'sp_test' }] });
    });
  });

  describe('GET /api/menu', () => {
    test('returns menu items', async () => {
      schemaService.buildMenu.mockResolvedValue([{ name: 'table1' }]);
      
      const res = await request(app).get('/api/menu?role=doctor');
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ role: 'doctor', items: [{ name: 'table1' }] });
      expect(schemaService.buildMenu).toHaveBeenCalledWith('doctor');
    });
  });
  
  describe('POST /api/routines/:name/execute', () => {
    test('executes routine', async () => {
      routinesService.executeRoutine.mockResolvedValue({ outputs: { result: 'ok' } });
      
      const res = await request(app)
        .post('/api/routines/sp_test/execute')
        .send({ params: { p1: 'v1' } });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({ routine: 'sp_test', outputs: { result: 'ok' } });
      expect(routinesService.executeRoutine).toHaveBeenCalledWith('sp_test', 'super_admin', { p1: 'v1' }, undefined);
    });
  });

});
