const pool = require('../config/database');

const createTodo = async (userId, locationId, taskTitle, taskDescription, reminderRadius) => {
  const [result] = await pool.execute(
    'INSERT INTO todos (user_id, location_id, task_title, task_description, reminder_radius) VALUES (?, ?, ?, ?, ?)',
    [userId, locationId, taskTitle, taskDescription, reminderRadius]
  );
  return result.insertId;
};

const getTodosByUserId = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT t.*, l.city, l.latitude, l.longitude, l.address, l.visit_date
     FROM todos t
     JOIN locations l ON t.location_id = l.id
     WHERE t.user_id = ?
     ORDER BY l.visit_date ASC`,
    [userId]
  );
  return rows;
};

const getTodoById = async (id) => {
  const [rows] = await pool.execute(
    `SELECT t.*, l.city, l.latitude, l.longitude, l.address, l.visit_date
     FROM todos t
     JOIN locations l ON t.location_id = l.id
     WHERE t.id = ?`,
    [id]
  );
  return rows[0] || null;
};

const updateTodo = async (id, fields) => {
  const allowedFields = ['task_title', 'task_description', 'status', 'reminder_radius', 'is_reminded'];
  const updates = [];
  const values = [];

  for (const field of allowedFields) {
    if (fields[field] !== undefined) {
      updates.push(`${field} = ?`);
      values.push(fields[field]);
    }
  }

  if (updates.length === 0) {
    return 0;
  }

  values.push(id);
  const [result] = await pool.execute(
    `UPDATE todos SET ${updates.join(', ')} WHERE id = ?`,
    values
  );
  return result.affectedRows;
};

const deleteTodo = async (id) => {
  const [result] = await pool.execute('DELETE FROM todos WHERE id = ?', [id]);
  return result.affectedRows;
};

const getTodosByStatus = async (userId, status) => {
  const [rows] = await pool.execute(
    `SELECT t.*, l.city, l.latitude, l.longitude, l.address, l.visit_date
     FROM todos t
     JOIN locations l ON t.location_id = l.id
     WHERE t.user_id = ? AND t.status = ?
     ORDER BY l.visit_date ASC`,
    [userId, status]
  );
  return rows;
};

const getTodosForToday = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT t.*, l.city, l.latitude, l.longitude, l.address, l.visit_date
     FROM todos t
     JOIN locations l ON t.location_id = l.id
     WHERE t.user_id = ? AND l.visit_date = CURDATE()
     ORDER BY t.id ASC`,
    [userId]
  );
  return rows;
};

const getUpcomingTodos = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT t.*, l.city, l.latitude, l.longitude, l.address, l.visit_date
     FROM todos t
     JOIN locations l ON t.location_id = l.id
     WHERE t.user_id = ? AND l.visit_date > CURDATE()
     ORDER BY l.visit_date ASC`,
    [userId]
  );
  return rows;
};

module.exports = {
  createTodo,
  getTodosByUserId,
  getTodoById,
  updateTodo,
  deleteTodo,
  getTodosByStatus,
  getTodosForToday,
  getUpcomingTodos,
};
