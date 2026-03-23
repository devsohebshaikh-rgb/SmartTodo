const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

async function setup() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });

  console.log('Connected to MySQL server.');

  const sqlPath = path.join(__dirname, 'database.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');

  console.log('Executing database.sql ...');
  await connection.query(sql);
  console.log('Database schema created successfully.');

  await connection.end();
  console.log('Connection closed.');
}

setup().catch((err) => {
  console.error('Setup failed:', err.message);
  process.exit(1);
});
