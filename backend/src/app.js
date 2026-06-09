const compression = require('compression');
const express = require('express');
const path = require('path');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const { mongoUri } = require('./config');
const { generalLimiter, authLimiter, apiLimiter, giftLimiter, messageLimiter } = require('./middleware/rateLimiter');
const mongoose = require('mongoose');
const logger = require('./utils/logger');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const AdminJS = require('adminjs');

AdminJS.registerAdapter(require('@adminjs/mongoose'));

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const roomsRoutes = require('./routes/rooms');
const messagesRoutes = require('./routes/messages');
const giftsRoutes = require('./routes/gifts');
const walletRoutes = require('./routes/wallet');
const paymentsRoutes = require('./routes/payments');
const agenciesRoutes = require('./routes/agencies');
const postsRoutes = require('./routes/posts');
const vehiclesRoutes = require('./routes/vehicles');
const vipRoutes = require('./routes/vip');
const tasksRoutes = require('./routes/tasks');
const adminRoutes = require('./routes/admin');

const app = express();

app.set('trust proxy', 1);

// Middlewares
app.use(compression());
app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(cors({
  origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : '*',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));

// Global rate limiter (falls back to memory store if Redis unavailable)
app.use(generalLimiter);

// Serve static assets (e.g., gift images/animations) from /public/assets
app.use('/assets', express.static(path.join(__dirname, '..', 'public', 'assets')));

// Routes (with granular rate limiters)
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/rooms', roomsRoutes);
app.use('/api/messages', messageLimiter, messagesRoutes);
app.use('/api', giftLimiter, giftsRoutes);
app.use('/api', walletRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/agencies', agenciesRoutes);
app.use('/api/posts', postsRoutes);
app.use('/api', vehiclesRoutes);
app.use('/api/vip', vipRoutes);
app.use('/api/tasks', tasksRoutes);
app.use('/api/admin', apiLimiter, adminRoutes);

// Health
app.get('/health', (req, res) => {
  const mongoose = require('mongoose');
  const dbOk = mongoose.connection.readyState === 1;
  res.json({ ok: true, db: dbOk ? 'connected' : 'disconnected', timestamp: new Date() });
});

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

// AdminJS (basic setup)
async function setupAdmin(app) {
  try {
    const adminJs = new AdminJS({
      databases: [mongoose],
      rootPath: '/admin',
      branding: {
        companyName: 'Lovers Admin',
        logo: false,
        softwareBrothers: false,
        theme: {
          colors: {
            primary100: '#0d6efd',
            primary80: '#0b5ed7',
            primary60: '#0a58ca',
            primary40: '#084298',
            primary20: '#06357a'
          }
        }
      }
    });
    const { default: AdminJSExpress } = await import('@adminjs/express');
    const router = AdminJSExpress.buildAuthenticatedRouter(adminJs, {
      authenticate: async (email, password) => {
        if (email === process.env.ADMIN_EMAIL && password === process.env.ADMIN_PASSWORD) {
          return { email };
        }
        return null;
      },
      cookieName: 'adminjs',
      cookiePassword: process.env.ADMIN_PASSWORD || 'adminjs-secret',
    });
    app.use(adminJs.options.rootPath, router);
  } catch (err) {
    logger.warn('AdminJS setup skipped:', err.message);
  }
}

module.exports = { app, setupAdmin };

