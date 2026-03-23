const notificationService = require('../services/notificationService');

const triggerNotification = async (req, res) => {
  try {
    const userId = req.user.id;
    const { todoId, message } = req.body;

    if (!todoId || !message) {
      return res.status(400).json({ success: false, message: 'Todo ID and message are required' });
    }

    const notificationId = await notificationService.createNotification(todoId, userId, message);

    return res.status(201).json({
      success: true,
      data: { id: notificationId, todoId, userId, message },
    });
  } catch (error) {
    console.error('Trigger notification error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getUserNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const notifications = await notificationService.getNotificationsByUserId(userId);

    return res.status(200).json({ success: true, data: notifications });
  } catch (error) {
    console.error('Get user notifications error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const markNotificationRead = async (req, res) => {
  try {
    const { id } = req.params;
    const affectedRows = await notificationService.updateNotificationStatus(id, 'read');

    if (affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.status(200).json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark notification read error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

module.exports = {
  triggerNotification,
  getUserNotifications,
  markNotificationRead,
};
