const sequelize = require('../../src/db');
const { QueryTypes } = require('sequelize');

async function runBenchmark() {
  console.log('Starting Benchmark...');
  
  try {
    await sequelize.authenticate();
    console.log('Database connected.');
  } catch (err) {
    console.error('Database connection failed. Skipping benchmark execution.');
    console.error('Reason:', err.message);
    console.log('\nNOTE: To run this benchmark, ensure your database is running and configured in backend/src/config.js');
    return;
  }

  const queries = [
    {
      name: 'Query 1: Find patient by ID (Indexed)',
      sql: 'SELECT * FROM patient WHERE patient_id = 100' // Assuming data exists
    },
    {
      name: 'Query 2: Count encounters for a doctor (Aggregation)',
      sql: 'SELECT COUNT(*) FROM encounter WHERE doctor_id = 1'
    },
    {
      name: 'Query 3: Recent encounters with patient details (Join)',
      sql: `
        SELECT e.encounter_id, p.patient_name, e.created_at
        FROM encounter e
        JOIN patient p ON e.patient_id = p.patient_id
        ORDER BY e.created_at DESC
        LIMIT 20
      `
    }
  ];

  console.log('\nRunning queries...');
  console.log('----------------------------------------');

  for (const q of queries) {
    try {
      const start = process.hrtime();
      await sequelize.query(q.sql, { type: QueryTypes.SELECT });
      const end = process.hrtime(start);
      const timeMs = (end[0] * 1000 + end[1] / 1e6).toFixed(2);
      console.log(`[${q.name}] Time: ${timeMs} ms`);
    } catch (err) {
      console.log(`[${q.name}] Failed: ${err.message}`);
    }
  }
  
  console.log('----------------------------------------');
  console.log('Benchmark completed.');
  process.exit(0);
}

runBenchmark();
