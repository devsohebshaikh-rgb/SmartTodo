const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const DEMO_PASSWORD = '123456';

async function seed() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'smart_todo',
  });

  console.log('Connected to smart_todo database.');

  // Hash the demo password with bcrypt
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, salt);
  console.log('Password hashed with bcrypt.');

  // Insert demo user
  const [userResult] = await connection.execute(
    'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
    ['Demo User', 'demo@demo.com', hashedPassword]
  );
  const userId = userResult.insertId;
  console.log(`Demo user created with id ${userId}.`);

  // Insert locations
  const locations = [
    [userId, 'Pune',   18.52040000, 73.85670000, 'Shivajinagar, Pune, Maharashtra 411005',     '2026-04-10'],
    [userId, 'Mumbai', 19.07600000, 72.87770000, 'Colaba Causeway, Mumbai, Maharashtra 400005', '2026-04-18'],
    [userId, 'Delhi',  28.61390000, 77.20900000, 'Connaught Place, New Delhi, Delhi 110001',     '2026-05-02'],
  ];

  const locationIds = [];
  for (const loc of locations) {
    const [result] = await connection.execute(
      'INSERT INTO locations (user_id, city, latitude, longitude, address, visit_date) VALUES (?, ?, ?, ?, ?, ?)',
      loc
    );
    locationIds.push(result.insertId);
    console.log(`Location "${loc[1]}" created with id ${result.insertId}.`);
  }

  // Insert todos
  const todos = [
    // Pune
    [userId, locationIds[0], 'Visit Aga Khan Palace',        'Explore the historical palace and museum.',             500, 'pending'],
    [userId, locationIds[0], 'Buy electronics from MG Road', 'Pick up USB-C hub and external SSD.',                   300, 'pending'],
    [userId, locationIds[0], 'Meet college friend',          'Catch up with Rahul at Vohuman Cafe, FC Road.',          700, 'in_progress'],
    // Mumbai
    [userId, locationIds[1], 'Client meeting at BKC',        'Present Q2 roadmap to the client team.',                1000, 'pending'],
    [userId, locationIds[1], 'Pick up parcel from courier',  'Collect Amazon return parcel from BlueDart office.',     400, 'pending'],
    [userId, locationIds[1], 'Dinner at Marine Drive',       'Try the new seafood restaurant near Nariman Point.',     600, 'pending'],
    // Delhi
    [userId, locationIds[2], 'Visit India Gate',             'Morning walk and photos at India Gate.',                  800, 'pending'],
    [userId, locationIds[2], 'Shopping at Sarojini Nagar',   'Buy winter clothes before the sale ends.',               500, 'pending'],
    [userId, locationIds[2], 'Document pickup from embassy', 'Collect attested documents from the embassy office.',     200, 'in_progress'],
  ];

  const todoIds = [];
  for (const todo of todos) {
    const [result] = await connection.execute(
      'INSERT INTO todos (user_id, location_id, task_title, task_description, reminder_radius, status) VALUES (?, ?, ?, ?, ?, ?)',
      todo
    );
    todoIds.push(result.insertId);
  }
  console.log(`${todos.length} todos created.`);

  // Insert sample notifications
  const notifications = [
    [todoIds[2], userId, 'You are near FC Road, Pune! Don\'t forget to meet Rahul at Vohuman Cafe.', 'sent'],
    [todoIds[8], userId, 'Reminder: You have a document pickup at the embassy in Delhi.',             'read'],
  ];

  for (const notif of notifications) {
    await connection.execute(
      'INSERT INTO notifications (todo_id, user_id, message, status) VALUES (?, ?, ?, ?)',
      notif
    );
  }
  console.log(`${notifications.length} notifications created.`);

  await connection.end();
  console.log('Seed complete. Connection closed.');
}

seed().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
