const pool = require('../config/database');

const createNotification = async (todoId, userId, message) => {
  const [result] = await pool.execute(
    'INSERT INTO notifications (todo_id, user_id, message) VALUES (?, ?, ?)',
    [todoId, userId, message]
  );
  return result.insertId;
};

const getNotificationsByUserId = async (userId) => {
  const [rows] = await pool.execute(
    'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
    [userId]
  );
  return rows;
};

const updateNotificationStatus = async (id, status) => {
  const [result] = await pool.execute(
    'UPDATE notifications SET status = ? WHERE id = ?',
    [status, id]
  );
  return result.affectedRows;
};

module.exports = {
  createNotification,
  getNotificationsByUserId,
  updateNotificationStatus,
};
