const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const notificationController = require('../controllers/notificationController');

router.use(auth);

router.post('/trigger', notificationController.triggerNotification);
router.get('/user/:id', notificationController.getUserNotifications);
router.put('/:id/read', notificationController.markNotificationRead);

module.exports = router;
