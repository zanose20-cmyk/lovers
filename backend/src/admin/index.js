const AdminJS = require('adminjs');
const AdminJSExpress = require('@adminjs/express');
const AdminJSMongoose = require('@adminjs/mongoose');
const mongoose = require('mongoose');
const User = require('../models/User');
const Room = require('../models/Room');
const Gift = require('../models/Gift');
const WalletTransaction = require('../models/WalletTransaction');

AdminJS.registerAdapter(AdminJSMongoose);

async function setupAdmin(app) {
  const adminJs = new AdminJS({
    databases: [mongoose],
    rootPath: '/admin',
    resources: [
      {
        resource: User,
        options: {
          properties: {
            _id: { isVisible: false },
            uid: { isTitle: true },
            password: { isVisible: false }
          },
          listProperties: ['userId', 'displayName', 'email', 'roles', 'isVerified', 'createdAt']
        }
      },
      {
        resource: Room,
        options: { listProperties: ['roomId', 'title', 'ownerId', 'type', 'capacity', 'createdAt'] }
      },
      {
        resource: Gift,
        options: { listProperties: ['sku', 'name', 'type', 'rarity', 'priceCoins'] }
      },
      {
        resource: WalletTransaction,
        options: { listProperties: ['txId', 'userId', 'type', 'amountCoins', 'createdAt'] }
      }
    ],
    branding: {
      companyName: 'Lovers Admin',
      logo: false,
      softwareBrothers: false
    }
  });

  const router = AdminJSExpress.buildAuthenticatedRouter(adminJs, {
    authenticate: async (email, password) => {
      if (email === process.env.ADMIN_EMAIL && password === process.env.ADMIN_PASSWORD) {
        return { email };
      }
      return null;
    },
    cookieName: 'adminjs',
    cookiePassword: process.env.ADMIN_PASSWORD || 'adminjs-secret'
  }, null, { resave: false, saveUninitialized: true });

  app.use(adminJs.options.rootPath, router);
}

module.exports = { setupAdmin };
