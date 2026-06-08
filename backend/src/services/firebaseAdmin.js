const admin = require('firebase-admin');
const config = require('../config');
const fs = require('fs');
const path = require('path');

function initFirebase() {
  if (admin.apps && admin.apps.length) return admin;

  if (config.firebaseServiceAccountPath) {
    const keyPath = path.resolve(__dirname, '..', '..', config.firebaseServiceAccountPath);
    if (!fs.existsSync(keyPath)) {
      console.warn('Firebase service account file not found at', keyPath);
    } else {
      const serviceAccount = require(keyPath);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      return admin;
    }
  }

  if (config.firebasePrivateKey && config.firebaseClientEmail && config.firebaseProjectId) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.firebaseProjectId,
        clientEmail: config.firebaseClientEmail,
        privateKey: config.firebasePrivateKey.replace(/\\n/g, '\n'),
      }),
    });
    return admin;
  }

  try {
    admin.initializeApp();
    return admin;
  } catch (e) {
    console.warn('Firebase not configured, running without Firebase:', e.message);
    return null;
  }
}

module.exports = { initFirebase, admin };
