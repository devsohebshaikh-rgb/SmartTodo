const pool = require('../config/database');

const createLocation = async (userId, city, latitude, longitude, address, visitDate) => {
  const [result] = await pool.execute(
    'INSERT INTO locations (user_id, city, latitude, longitude, address, visit_date) VALUES (?, ?, ?, ?, ?, ?)',
    [userId, city, latitude, longitude, address, visitDate]
  );
  return result.insertId;
};

const getLocationsByUserId = async (userId) => {
  const [rows] = await pool.execute(
    'SELECT * FROM locations WHERE user_id = ? ORDER BY visit_date ASC',
    [userId]
  );
  return rows;
};

const getLocationById = async (id) => {
  const [rows] = await pool.execute('SELECT * FROM locations WHERE id = ?', [id]);
  return rows[0] || null;
};

const deleteLocation = async (id) => {
  const [result] = await pool.execute('DELETE FROM locations WHERE id = ?', [id]);
  return result.affectedRows;
};

module.exports = {
  createLocation,
  getLocationsByUserId,
  getLocationById,
  deleteLocation,
};
