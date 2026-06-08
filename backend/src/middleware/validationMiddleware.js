const logger = require('../utils/logger');

/**
 * Validates required fields in request body
 * @param {string[]} fields - Array of required field names
 */
function requireFields(...fields) {
  return (req, res, next) => {
    const missing = [];
    for (const field of fields) {
      if (req.body[field] === undefined || req.body[field] === null || req.body[field] === '') {
        missing.push(field);
      }
    }
    if (missing.length > 0) {
      return res.status(400).json({ error: `Missing required fields: ${missing.join(', ')}` });
    }
    next();
  };
}

/**
 * Validates request body against a schema
 * @param {Object} schema - Validation schema { field: { type, required, min, max, regex } }
 */
function validateBody(schema) {
  return (req, res, next) => {
    const errors = [];
    
    for (const [field, rules] of Object.entries(schema)) {
      const value = req.body[field];
      
      if (rules.required && (value === undefined || value === null || value === '')) {
        errors.push(`${field} is required`);
        continue;
      }
      
      if (value === undefined || value === null) continue;
      
      if (rules.type === 'string' && typeof value !== 'string') {
        errors.push(`${field} must be a string`);
      }
      if (rules.type === 'number' && typeof value !== 'number') {
        errors.push(`${field} must be a number`);
      }
      if (rules.type === 'boolean' && typeof value !== 'boolean') {
        errors.push(`${field} must be a boolean`);
      }
      if (rules.type === 'array' && !Array.isArray(value)) {
        errors.push(`${field} must be an array`);
      }
      
      if (rules.min !== undefined && typeof value === 'number' && value < rules.min) {
        errors.push(`${field} must be at least ${rules.min}`);
      }
      if (rules.max !== undefined && typeof value === 'number' && value > rules.max) {
        errors.push(`${field} must be at most ${rules.max}`);
      }
      
      if (rules.regex && typeof value === 'string' && !rules.regex.test(value)) {
        errors.push(`${field} format is invalid`);
      }
      
      if (rules.minLength && typeof value === 'string' && value.length < rules.minLength) {
        errors.push(`${field} must be at least ${rules.minLength} characters`);
      }
      if (rules.maxLength && typeof value === 'string' && value.length > rules.maxLength) {
        errors.push(`${field} must be at most ${rules.maxLength} characters`);
      }
      
      if (rules.enum && !rules.enum.includes(value)) {
        errors.push(`${field} must be one of: ${rules.enum.join(', ')}`);
      }
    }
    
    if (errors.length > 0) {
      return res.status(400).json({ error: errors[0], details: errors });
    }
    
    next();
  };
}

/**
 * Validates query parameters
 */
function validateQuery(schema) {
  return (req, res, next) => {
    const errors = [];
    
    for (const [field, rules] of Object.entries(schema)) {
      const value = req.query[field];
      
      if (rules.required && (value === undefined || value === '')) {
        errors.push(`Query parameter ${field} is required`);
        continue;
      }
      
      if (value === undefined) continue;
      
      if (rules.type === 'number' && isNaN(Number(value))) {
        errors.push(`${field} must be a number`);
      }
      if (rules.enum && !rules.enum.includes(value)) {
        errors.push(`${field} must be one of: ${rules.enum.join(', ')}`);
      }
    }
    
    if (errors.length > 0) {
      return res.status(400).json({ error: errors[0] });
    }
    
    next();
  };
}

module.exports = { requireFields, validateBody, validateQuery };
