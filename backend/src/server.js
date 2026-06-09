const http = require('http');
const mongoose = require('mongoose');
const { app, setupAdmin } = require('./app');
const config = require('./config');
const logger = require('./utils/logger');

async function start() {
  try {
    // Connect to MongoDB
    await mongoose.connect(config.mongoUri);
    logger.info('✅ Connected to MongoDB');
    
    // Setup AdminJS
    await setupAdmin(app);
    logger.info('✅ AdminJS dashboard initialized');
    
    // Create HTTP server
    const server = http.createServer(app);
    
    // Initialize Socket.io
    const { initSocket } = require('./services/socket');
    initSocket(server);
    logger.info('✅ Socket.io initialized');
    
    // Initialize Firebase Admin
    const { initFirebase } = require('./services/firebase');
    initFirebase();
    logger.info('✅ Firebase initialized');
    
    // Start listening
    const port = config.port;
    server.listen(port, () => {
      logger.info(`🚀 Server running on port ${port}`);
      logger.info(`📝 Admin: http://localhost:${port}/admin`);
      logger.info(`❤️  Health: http://localhost:${port}/health`);
    });
  } catch (err) {
    logger.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  setTimeout(() => process.exit(1), 2000);
});

process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

start();
