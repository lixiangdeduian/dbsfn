const request = require('supertest');

// Mock dependencies (same as integration, but we can make them more stateful if needed)
jest.mock('../../src/db', () => ({
  query: jest.fn(),
  authenticate: jest.fn().mockResolvedValue(),
  transaction: jest.fn(cb => cb('mockTransaction')),
  close: jest.fn()
}));

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

describe('System Workflow Tests', () => {
  
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('Doctor Workflow: Login -> Menu -> Execute Routine', async () => {
    // Step 1: Client fetches roles to show login screen
    schemaService.listRoles.mockReturnValue(['doctor', 'nurse', 'admin']);
    const rolesRes = await request(app).get('/api/roles');
    expect(rolesRes.statusCode).toBe(200);
    expect(rolesRes.body.roles).toContain('doctor');

    // Step 2: Doctor "logs in" (selects role) and fetches menu
    const role = 'doctor';
    schemaService.buildMenu.mockResolvedValue([
      { name: 'patient', displayName: 'Patients' },
      { name: 'appointment', displayName: 'Appointments' }
    ]);
    const menuRes = await request(app).get(`/api/menu?role=${role}`);
    expect(menuRes.statusCode).toBe(200);
    expect(menuRes.body.role).toBe(role);
    expect(menuRes.body.items).toHaveLength(2);

    // Step 3: Doctor looks for routines
    routinesService.listRoutines.mockResolvedValue([
      { name: 'sp_get_patient_details', displayName: 'Get Patient Details' }
    ]);
    const routinesRes = await request(app).get('/api/routines');
    expect(routinesRes.statusCode).toBe(200);
    expect(routinesRes.body.routines).toEqual(
      expect.arrayContaining([expect.objectContaining({ name: 'sp_get_patient_details' })])
    );

    // Step 4: Doctor executes a routine to get patient details
    routinesService.executeRoutine.mockResolvedValue({
      outputs: { patient_name: 'John Doe' },
      resultSets: []
    });
    const execRes = await request(app)
      .post('/api/routines/sp_get_patient_details/execute')
      .query({ role }) // Passing role in query as per server.js logic
      .send({ params: { patient_id: 1 } });
    
    expect(execRes.statusCode).toBe(200);
    expect(execRes.body.outputs.patient_name).toBe('John Doe');
    expect(routinesService.executeRoutine).toHaveBeenCalledWith(
      'sp_get_patient_details',
      role,
      { patient_id: 1 },
      undefined
    );
  });

  test('Nurse Workflow: Login -> Menu -> Assign Bed', async () => {
    const role = 'nurse';
    schemaService.buildMenu.mockResolvedValue([
      { name: 'inpatient_admission', displayName: 'Inpatient Admissions' },
      { name: 'bed', displayName: 'Beds' }
    ]);

    // Nurse login & menu
    const menuRes = await request(app).get(`/api/menu?role=${role}`);
    expect(menuRes.statusCode).toBe(200);
    expect(menuRes.body.role).toBe(role);

    // Nurse executes sp_inpatient_admit
    routinesService.executeRoutine.mockResolvedValue({
      outputs: { o_encounter_id: 101, o_bed_assignment_id: 201 },
      resultSets: []
    });

    const execRes = await request(app)
      .post('/api/routines/sp_inpatient_admit/execute')
      .query({ role })
      .send({ params: { p_patient_id: 1, p_department_id: 2 } });

    expect(execRes.statusCode).toBe(200);
    expect(execRes.body.outputs.o_encounter_id).toBe(101);
    expect(routinesService.executeRoutine).toHaveBeenCalledWith(
      'sp_inpatient_admit',
      role,
      expect.anything(),
      undefined
    );
  });

  test('Pharmacist Workflow: Login -> Menu -> Dispense Drug', async () => {
    const role = 'pharmacist';
    schemaService.buildMenu.mockResolvedValue([
      { name: 'prescription', displayName: 'Prescriptions' },
      { name: 'drug_inventory', displayName: 'Inventory' }
    ]);

    // Pharmacist login
    const menuRes = await request(app).get(`/api/menu?role=${role}`);
    expect(menuRes.statusCode).toBe(200);

    // Pharmacist executes sp_pharmacy_dispense (assuming this routine exists or is simulated)
    routinesService.executeRoutine.mockResolvedValue({
      outputs: { o_status: 'SUCCESS' },
      resultSets: []
    });

    const execRes = await request(app)
      .post('/api/routines/sp_pharmacy_dispense/execute')
      .query({ role })
      .send({ params: { p_prescription_id: 500 } });

    expect(execRes.statusCode).toBe(200);
    expect(execRes.body.outputs.o_status).toBe('SUCCESS');
  });

  test('Lab Tech Workflow: Login -> Menu -> Enter Result', async () => {
    const role = 'lab_tech';
    schemaService.buildMenu.mockResolvedValue([
      { name: 'lab_order', displayName: 'Lab Orders' }
    ]);

    // Lab Tech login
    const menuRes = await request(app).get(`/api/menu?role=${role}`);
    expect(menuRes.statusCode).toBe(200);

    // Lab Tech enters result
    routinesService.executeRoutine.mockResolvedValue({
      outputs: { o_status: 'REPORTED' },
      resultSets: []
    });

    const execRes = await request(app)
      .post('/api/routines/sp_lab_result_enter/execute')
      .query({ role })
      .send({ params: { p_lab_order_item_id: 800, p_result_value: '5.5' } });

    expect(execRes.statusCode).toBe(200);
    expect(execRes.body.outputs.o_status).toBe('REPORTED');
  });

  test('Patient Workflow: Login -> View Records', async () => {
    const role = 'patient';
    schemaService.buildMenu.mockResolvedValue([
      { name: 'my_encounters', displayName: 'My Encounters' },
      { name: 'my_prescriptions', displayName: 'My Prescriptions' }
    ]);

    // Patient login
    const menuRes = await request(app).get(`/api/menu?role=${role}`);
    expect(menuRes.statusCode).toBe(200);
    expect(menuRes.body.role).toBe(role);

    // Patient cannot execute doctor routines (simulated by service throwing error or permission check)
    // Here we just test that they can access their menu, which is the entry point for viewing records
  });
});
