const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const path = require('path');

// Configure Cloudinary if credentials are provided
const isCloudinaryConfigured = 
  process.env.CLOUDINARY_CLOUD_NAME && 
  process.env.CLOUDINARY_API_KEY && 
  process.env.CLOUDINARY_API_SECRET;

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  console.log('Cloudinary configured successfully.');
} else {
  console.warn('Cloudinary credentials missing in .env. Falling back to local file storage.');
}

/**
 * Uploads an image file to Cloudinary or falls back to local storage if credentials are missing
 * @param {Object} file - Express multer file object
 * @returns {Promise<string>} - The URL of the uploaded image
 */
const uploadImage = async (file) => {
  if (!file) return '';

  if (isCloudinaryConfigured) {
    try {
      // Upload using streamifier or directly with temp path / buffer
      // Since multer stores file, we can upload using file path
      const result = await cloudinary.uploader.upload(file.path, {
        folder: 'chatapp',
      });
      // Delete temporary local file
      try {
        fs.unlinkSync(file.path);
      } catch (err) {
        console.error('Failed to delete temp file:', err);
      }
      return result.secure_url;
    } catch (error) {
      console.error('Cloudinary Upload Error:', error);
      throw new Error('Image upload failed');
    }
  } else {
    // Local fallback: move file to static uploads folder
    try {
      const uploadDir = path.join(__dirname, '..', 'public', 'uploads');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }

      const filename = `${Date.now()}-${file.originalname.replace(/\s+/g, '_')}`;
      const destPath = path.join(uploadDir, filename);

      fs.renameSync(file.path, destPath);
      
      // Return relative url or absolute path that can be requested from frontend
      // We will make public/uploads static in app.js
      return `/uploads/${filename}`;
    } catch (error) {
      console.error('Local File Upload Error:', error);
      throw new Error('Local image upload failed');
    }
  }
};

module.exports = {
  cloudinary,
  uploadImage,
  isCloudinaryConfigured
};
