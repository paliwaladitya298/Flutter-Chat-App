const express = require('express');
const { accessChat, getChats } = require('../controllers/chatController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.route('/').post(protect, accessChat).get(protect, getChats);

module.exports = router;
