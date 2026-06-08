const dotenv = require('dotenv');
const path = require('path');

// Load .env from project root
dotenv.config({ path: path.join(__dirname, '..', '..', '.env') });

module.exports = {
  port: process.env.PORT || 3000,
  mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/lovers',
  redisUrl: process.env.REDIS_URL,
  
  jwtSecret: process.env.JWT_SECRET || 'change_me_to_random_string_in_production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
  
  // Firebase
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_JSON_PATH,
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID,
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  firebasePrivateKey: process.env.FIREBASE_PRIVATE_KEY,
  
  // Voice Engine: 'agora' or 'jitsi'
  voiceEngine: process.env.VOICE_ENGINE || 'jitsi',
  agoraAppId: process.env.AGORA_APP_ID,
  agoraAppCertificate: process.env.AGORA_APP_CERTIFICATE,
  jitsiServer: process.env.JITSI_SERVER || 'https://meet.jit.si',
  jitsiJwtSecret: process.env.JITSI_JWT_SECRET,
  
  // Admin panel
  adminEmail: process.env.ADMIN_EMAIL || 'admin@lovers.app',
  adminPassword: process.env.ADMIN_PASSWORD || 'admin123',
  
  // Stripe
  stripeSecretKey: process.env.STRIPE_SECRET_KEY,
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  
  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
  
  // CORS
  corsOrigin: process.env.CORS_ORIGIN,
};
