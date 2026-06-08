const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

/**
 * Upload a file buffer to Firebase Storage
 * @param {Buffer} fileBuffer - The file buffer
 * @param {string} mimeType - MIME type of the file
 * @param {string} path - Storage path (e.g., 'avatars', 'covers', 'posts')
 * @param {string} fileName - Optional file name (generated if not provided)
 * @returns {Promise<string>} - Download URL
 */
async function uploadFile(fileBuffer, mimeType, path = 'uploads', fileName = null) {
  try {
    const bucket = admin.storage().bucket();
    const ext = mimeType.split('/')[1] || 'bin';
    const name = fileName || `${uuidv4()}.${ext}`;
    const filePath = `${path}/${name}`;
    
    const file = bucket.file(filePath);
    
    await file.save(fileBuffer, {
      metadata: { contentType: mimeType },
      public: true
    });
    
    // Make public
    await file.makePublic();
    
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
    return publicUrl;
  } catch (err) {
    logger.error('uploadFile error', err);
    throw new Error('Failed to upload file');
  }
}

/**
 * Upload a file from a URL to Firebase Storage
 * @param {string} fileUrl - Source URL
 * @param {string} path - Storage path
 * @returns {Promise<string>} - Download URL
 */
async function uploadFromUrl(fileUrl, path = 'uploads') {
  try {
    const https = require('https');
    const http = require('http');
    
    return new Promise((resolve, reject) => {
      const client = fileUrl.startsWith('https') ? https : http;
      client.get(fileUrl, async (response) => {
        const chunks = [];
        response.on('data', chunk => chunks.push(chunk));
        response.on('end', async () => {
          try {
            const buffer = Buffer.concat(chunks);
            const contentType = response.headers['content-type'] || 'image/jpeg';
            const url = await uploadFile(buffer, contentType, path);
            resolve(url);
          } catch (err) {
            reject(err);
          }
        });
      }).on('error', reject);
    });
  } catch (err) {
    logger.error('uploadFromUrl error', err);
    throw new Error('Failed to upload from URL');
  }
}

/**
 * Delete a file from Firebase Storage
 * @param {string} fileUrl - The full URL of the file to delete
 */
async function deleteFile(fileUrl) {
  try {
    const bucket = admin.storage().bucket();
    
    // Extract the file path from the URL
    const baseUrl = `https://storage.googleapis.com/${bucket.name}/`;
    if (!fileUrl.startsWith(baseUrl)) {
      // File is not in our bucket, skip
      return;
    }
    
    const filePath = fileUrl.replace(baseUrl, '');
    await bucket.file(filePath).delete();
  } catch (err) {
    logger.error('deleteFile error', err);
    // Don't throw - deletion is not critical
  }
}

module.exports = { uploadFile, uploadFromUrl, deleteFile };
