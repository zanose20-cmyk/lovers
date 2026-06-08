const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const { createClient } = require('redis');
const config = require('../config');

/**
 * Creates a rate limiter middleware
 * @param {Object} options
 * @param {number} options.windowMs - Time window in milliseconds (default: 1 minute)
 * @param {number} options.max - Max requests per window (default: 60)
 * @param {string} options.message - Error message (default: 'Too many requests')
 */
function createRateLimiter({ windowMs = 60 * 1000, max = 60, message = 'Too many requests, please try again later' } = {}) {
  const options = {
    windowMs,
    max,
    message: { error: message, code: 'RATE_LIMIT_EXCEEDED' },
    standardHeaders: true,
    legacyHeaders: false,
  };

  // Use Redis store if available
  if (config.redisUrl) {
    try {
      const client = createClient({ url: config.redisUrl });
      client.connect().catch(err => console.warn('Redis rate limiter connect failed:', err.message));
      
      options.store = new RedisStore({
        sendCommand: (...args) => client.sendCommand(args),
      });
    } catch (err) {
      console.warn('Redis rate limiter unavailable, using memory store');
    }
  }

  return rateLimit(options);
}

// Pre-defined rate limiters
const generalLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 200,
  message: 'Too many requests'
});

const authLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  message: 'Too many login attempts, please try again after 15 minutes'
});

const apiLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 100,
  message: 'API rate limit exceeded'
});

const giftLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Gift sending rate limit exceeded'
});

const messageLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 60,
  message: 'Message rate limit exceeded'
});

module.exports = {
  createRateLimiter,
  generalLimiter,
  authLimiter,
  apiLimiter,
  giftLimiter,
  messageLimiter
};
