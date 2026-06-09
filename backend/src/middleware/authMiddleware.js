const jwt = require('jsonwebtoken');
const config = require('../config');
const User = require('../models/User');

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ error: 'Unauthorized' });
  const parts = auth.split(' ');
  if (parts.length !== 2) return res.status(401).json({ error: 'Malformed token' });
  const token = parts[1];
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    const user = await User.findOne({ userId: payload.userId }).select('banned banReason').lean();
    if (user && user.banned) {
      return res.status(403).json({ error: 'Account banned', reason: user.banReason || '' });
    }
    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = { requireAuth };
