/**
 * Cleanup script for expired data
 * Run periodically (e.g., with cron) to clean up:
 * - Expired vehicle rentals
 * - Old notifications
 * - Expired daily task progress
 * - Soft-deleted messages older than 30 days
 * - Old admin logs
 */

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '..', '..', '.env') });

const User = require('../models/User');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const AdminLog = require('../models/AdminLog');
const UserDailyProgress = require('../models/UserDailyProgress');
const logger = require('../utils/logger');

async function cleanup() {
  const start = Date.now();
  logger.info('🧹 Starting cleanup...');

  try {
    await mongoose.connect(process.env.MONGO_URI);
    logger.info('Connected to MongoDB');

    // 1. Remove expired vehicle rentals
    const now = new Date();
    const vehicleResult = await User.updateMany(
      { 'vehicles.expiresAt': { $lt: now } },
      { $pull: { vehicles: { expiresAt: { $lt: now } } } }
    );
    logger.info(`✅ Expired vehicles cleaned: ${vehicleResult.modifiedCount} users`);

    // 2. Delete old soft-deleted messages (older than 30 days)
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const msgResult = await Message.deleteMany({
      isDeleted: true,
      createdAt: { $lt: thirtyDaysAgo }
    });
    logger.info(`✅ Old deleted messages removed: ${msgResult.deletedCount}`);

    // 3. Delete old notifications (older than 90 days)
    const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
    const notifResult = await Notification.deleteMany({
      createdAt: { $lt: ninetyDaysAgo }
    });
    logger.info(`✅ Old notifications removed: ${notifResult.deletedCount}`);

    // 4. Clean up old daily progress (older than 7 days)
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const progressResult = await UserDailyProgress.deleteMany({
      date: { $lt: sevenDaysAgo }
    });
    logger.info(`✅ Old daily progress cleaned: ${progressResult.deletedCount}`);

    // 5. Clean old admin logs (older than 180 days)
    const oneEightyDaysAgo = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);
    const logResult = await AdminLog.deleteMany({
      createdAt: { $lt: oneEightyDaysAgo }
    });
    logger.info(`✅ Old admin logs cleaned: ${logResult.deletedCount}`);

    const duration = Date.now() - start;
    logger.info(`🎉 Cleanup completed in ${duration}ms`);
    process.exit(0);
  } catch (err) {
    logger.error('❌ Cleanup error:', err);
    process.exit(1);
  }
}

// Run directly
if (require.main === module) {
  cleanup();
}

module.exports = cleanup;
