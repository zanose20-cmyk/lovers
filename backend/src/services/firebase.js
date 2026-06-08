const admin = require('firebase-admin');
const config = require('../config');
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized) return;
  
  try {
    if (config.firebaseServiceAccountPath) {
      const keyPath = path.resolve(__dirname, '..', '..', config.firebaseServiceAccountPath);
      if (!fs.existsSync(keyPath)) {
        logger.warn('Firebase service account not found at', keyPath);
        return;
      }
      const serviceAccount = require(keyPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: `${serviceAccount.project_id}.appspot.com`
      });
      firebaseInitialized = true;
      logger.info('Firebase initialized via service account file');
      return;
    }
    
    if (config.firebaseProjectId && config.firebaseClientEmail && config.firebasePrivateKey) {
      const privateKey = config.firebasePrivateKey.replace(/\\n/g, '\n');
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.firebaseProjectId,
          clientEmail: config.firebaseClientEmail,
          privateKey: privateKey,
        }),
        storageBucket: `${config.firebaseProjectId}.appspot.com`
      });
      firebaseInitialized = true;
      logger.info('Firebase initialized via environment variables');
      return;
    }
  } catch (err) {
    logger.warn('Firebase initialization skipped:', err.message);
  }
}

/**
 * Verify a Firebase ID token
 * @param {string} idToken 
 * @returns {Promise<object|null>} Decoded token or null
 */
async function verifyIdToken(idToken) {
  if (!firebaseInitialized) {
    logger.warn('Firebase not initialized, cannot verify token');
    return null;
  }
  
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded;
  } catch (err) {
    logger.error('Firebase token verification failed:', err.message);
    return null;
  }
}

/**
 * Get Firebase admin instance
 */
function getAdmin() {
  return admin;
}

module.exports = { initFirebase, verifyIdToken, getAdmin };
