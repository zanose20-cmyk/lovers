const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Allowed MIME types
const ALLOWED_TYPES = {
  image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'],
  video: ['video/mp4', 'video/webm', 'video/ogg'],
  audio: ['audio/mpeg', 'audio/ogg', 'audio/wav', 'audio/webm'],
  document: ['application/pdf', 'application/json'],
};

// File size limits (in bytes)
const MAX_SIZES = {
  image: 5 * 1024 * 1024,     // 5MB
  video: 50 * 1024 * 1024,    // 50MB
  audio: 10 * 1024 * 1024,    // 10MB
  default: 10 * 1024 * 1024,  // 10MB
};

/**
 * Creates a multer upload middleware for specific file types
 * @param {'image'|'video'|'audio'|'document'} type - Type of file
 * @param {string} fieldName - Form field name
 * @param {number} maxCount - Maximum number of files
 */
function createUpload(type = 'image', fieldName = 'file', maxCount = 1) {
  const allowedMimes = ALLOWED_TYPES[type] || ALLOWED_TYPES.image;
  const maxSize = MAX_SIZES[type] || MAX_SIZES.default;

  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadPath = path.join(__dirname, '..', '..', 'uploads', type);
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      const name = `${uuidv4()}${ext}`;
      cb(null, name);
    }
  });

  const fileFilter = (req, file, cb) => {
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type: ${file.mimetype}. Allowed: ${allowedMimes.join(', ')}`), false);
    }
  };

  return multer({
    storage,
    fileFilter,
    limits: { fileSize: maxSize, files: maxCount }
  }).array(fieldName, maxCount);
}

/**
 * Upload middleware for single avatar image
 */
const uploadAvatar = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_TYPES.image.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed (jpeg, png, gif, webp)'), false);
    }
  }
}).single('avatar');

/**
 * Upload middleware for gift media (images, animations)
 */
const uploadGiftMedia = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = [...ALLOWED_TYPES.image, ...ALLOWED_TYPES.video];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid gift media type'), false);
    }
  }
}).single('media');

/**
 * Upload middleware for post attachments
 */
const uploadPostAttachments = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024, files: 10 },
  fileFilter: (req, file, cb) => {
    const allowed = [...ALLOWED_TYPES.image, ...ALLOWED_TYPES.video, ...ALLOWED_TYPES.audio];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid attachment type'), false);
    }
  }
}).array('attachments', 10);

module.exports = {
  createUpload,
  uploadAvatar,
  uploadGiftMedia,
  uploadPostAttachments,
  ALLOWED_TYPES,
  MAX_SIZES
};
