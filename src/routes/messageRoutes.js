const express = require('express');
const { sendMessage, getMessages, uploadMessageImage } = require('../controllers/messageController');
const { protect } = require('../middleware/authMiddleware');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// Configure multer temporary upload destination
const tempDir = path.join(__dirname, '..', '..', 'temp_uploads');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

const upload = multer({ 
  dest: tempDir,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});

const router = express.Router();

router.route('/').post(protect, sendMessage);
router.route('/:chatId').get(protect, getMessages);
router.route('/upload').post(protect, upload.single('image'), uploadMessageImage);

module.exports = router;
