const locationService = require('../services/locationService');

const createLocation = async (req, res) => {
  try {
    const userId = req.user.id;
    const { city, latitude, longitude, address, visitDate } = req.body;

    if (!city || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'City, latitude, and longitude are required' });
    }

    const locationId = await locationService.createLocation(userId, city, latitude, longitude, address, visitDate);
    const location = await locationService.getLocationById(locationId);

    return res.status(201).json({ success: true, data: location });
  } catch (error) {
    console.error('Create location error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getUserLocations = async (req, res) => {
  try {
    const userId = req.user.id;
    const locations = await locationService.getLocationsByUserId(userId);

    return res.status(200).json({ success: true, data: locations });
  } catch (error) {
    console.error('Get user locations error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getLocation = async (req, res) => {
  try {
    const { id } = req.params;
    const location = await locationService.getLocationById(id);

    if (!location) {
      return res.status(404).json({ success: false, message: 'Location not found' });
    }

    return res.status(200).json({ success: true, data: location });
  } catch (error) {
    console.error('Get location error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

module.exports = {
  createLocation,
  getUserLocations,
  getLocation,
};
