const fs = require('fs');
const path = require('path');
const sequelize = require('../src/db');

async function run() {
  try {
    const staffViews = fs.readFileSync(path.resolve(__dirname, '../../database/sql/security/3_views_staff.sql'), 'utf8');
    const patientViews = fs.readFileSync(path.resolve(__dirname, '../../database/sql/security/2_views_patient.sql'), 'utf8');

    // Split by semi-colon to get individual statements?
    // But views creation might contain semi-colons inside...
    // The files seem to contain valid SQL.
    // Usually these files have delimiters or just semicolons.
    // The `Read` output shows they use `;` at end of statements.
    // And `1_procedure.sql` used `DELIMITER $$`.
    // These view files don't seem to use DELIMITER.
    
    // I'll execute the whole file content if sequelize supports multiple statements.
    // Sequelize usually doesn't support multiple statements by default unless configured.
    // But I can split by `;\n` or `CREATE OR REPLACE`.
    
    // Let's just manually construct the queries for the two views I changed.
    // Or better, just read the file and split by `;\n`.
    
    const queries = [];
    
    // Helper to push queries from file content
    const pushQueries = (content) => {
        const statements = content.split(';').map(s => s.trim()).filter(s => s.length > 0);
        queries.push(...statements);
    };

    pushQueries(staffViews);
    pushQueries(patientViews);

    console.log(`Found ${queries.length} queries.`);

    for (const q of queries) {
      const qClean = q.replace(/--.*$/gm, '').trim();
      if (qClean.length === 0) continue;
      
      if (qClean.toUpperCase().startsWith('CREATE') || qClean.toUpperCase().startsWith('DROP') || qClean.toUpperCase().startsWith('GRANT')) {
          const short = qClean.substring(0, 100).replace(/\n/g, ' ');
          console.log(`Executing: ${short}...`);
          try {
            await sequelize.query(q);
          } catch (e) {
            console.error(`Failed to execute: ${short}`);
            console.error(e);
          }
      }
    }

    console.log('Views updated successfully.');
  } catch (err) {
    console.error('Error updating views:', err);
  } finally {
    await sequelize.close();
  }
}

run();
