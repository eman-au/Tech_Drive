const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

// Define user routes
// The verifyToken middleware ensures that only authenticated users can access their profile
router.get('/profile', verifyToken, userController.getProfile);

module.exports = router;
