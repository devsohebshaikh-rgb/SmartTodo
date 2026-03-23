const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const locationController = require('../controllers/locationController');

router.use(auth);

router.post('/', locationController.createLocation);
router.get('/user/:id', locationController.getUserLocations);
router.get('/:id', locationController.getLocation);

module.exports = router;
