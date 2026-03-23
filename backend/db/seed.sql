-- Smart Location Todo App - Seed Data
-- Note: Use seed.js instead for proper bcrypt password hashing.
-- This file is provided as a reference / fallback.

USE smart_todo;

-- Demo user (password hash is a placeholder; use seed.js for real bcrypt)
INSERT INTO users (name, email, password) VALUES
('Demo User', 'demo@demo.com', '$2a$10$8KzQ5x5z5z5z5z5z5z5z5.8KzQ5x5z5z5z5z5z5z5z5.hash123');

-- Locations (user_id = 1 assumes demo user is first insert)
INSERT INTO locations (user_id, city, latitude, longitude, address, visit_date) VALUES
(1, 'Pune',   18.52040000, 73.85670000, 'Shivajinagar, Pune, Maharashtra 411005',       '2026-04-10'),
(1, 'Mumbai', 19.07600000, 72.87770000, 'Colaba Causeway, Mumbai, Maharashtra 400005',   '2026-04-18'),
(1, 'Delhi',  28.61390000, 77.20900000, 'Connaught Place, New Delhi, Delhi 110001',       '2026-05-02');

-- Todos for Pune (location_id = 1)
INSERT INTO todos (user_id, location_id, task_title, task_description, reminder_radius, status) VALUES
(1, 1, 'Visit Aga Khan Palace',        'Explore the historical palace and museum.',             500, 'pending'),
(1, 1, 'Buy electronics from MG Road', 'Pick up USB-C hub and external SSD.',                   300, 'pending'),
(1, 1, 'Meet college friend',          'Catch up with Rahul at Vohuman Cafe, FC Road.',          700, 'in_progress');

-- Todos for Mumbai (location_id = 2)
INSERT INTO todos (user_id, location_id, task_title, task_description, reminder_radius, status) VALUES
(1, 2, 'Client meeting at BKC',        'Present Q2 roadmap to the client team.',                1000, 'pending'),
(1, 2, 'Pick up parcel from courier',  'Collect Amazon return parcel from BlueDart office.',     400, 'pending'),
(1, 2, 'Dinner at Marine Drive',       'Try the new seafood restaurant near Nariman Point.',     600, 'pending');

-- Todos for Delhi (location_id = 3)
INSERT INTO todos (user_id, location_id, task_title, task_description, reminder_radius, status) VALUES
(1, 3, 'Visit India Gate',             'Morning walk and photos at India Gate.',                  800, 'pending'),
(1, 3, 'Shopping at Sarojini Nagar',   'Buy winter clothes before the sale ends.',               500, 'pending'),
(1, 3, 'Document pickup from embassy', 'Collect attested documents from the embassy office.',     200, 'in_progress');

-- Sample notifications
INSERT INTO notifications (todo_id, user_id, message, status) VALUES
(3, 1, 'You are near FC Road, Pune! Don''t forget to meet Rahul at Vohuman Cafe.', 'sent'),
(9, 1, 'Reminder: You have a document pickup at the embassy in Delhi.',             'read');
