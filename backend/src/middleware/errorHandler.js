const logger = require('../utils/logger');

class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
  }
}

class ValidationError extends AppError {
  constructor(message, details = []) {
    super(message, 400, 'VALIDATION_ERROR');
    this.details = details;
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403, 'FORBIDDEN');
  }
}

class ConflictError extends AppError {
  constructor(message = 'Resource already exists') {
    super(message, 409, 'CONFLICT');
  }
}

function errorHandler(err, req, res, next) {
  if (err.isOperational) {
    logger.warn('Operational error', { 
      code: err.code, 
      message: err.message, 
      statusCode: err.statusCode,
      path: req.path,
      method: req.method
    });
    
    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code,
      details: err.details || undefined
    });
  }
  
  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message);
    return res.status(400).json({
      error: messages[0],
      code: 'VALIDATION_ERROR',
      details: messages
    });
  }
  
  // Mongoose duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return res.status(409).json({
      error: `${field} already exists`,
      code: 'DUPLICATE_KEY'
    });
  }
  
  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ error: 'Invalid token', code: 'INVALID_TOKEN' });
  }
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
  }
  
  // Firebase errors
  if (err.code && err.code.startsWith('auth/')) {
    return res.status(401).json({ 
      error: err.message || 'Authentication failed', 
      code: err.code 
    });
  }
  
  // Unknown errors
  logger.error('Unexpected error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  });
  
  res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR'
  });
}

// 404 handler for unknown routes
function notFoundHandler(req, res) {
  res.status(404).json({
    error: `Route ${req.method} ${req.path} not found`,
    code: 'ROUTE_NOT_FOUND'
  });
}

module.exports = {
  errorHandler,
  notFoundHandler,
  AppError,
  ValidationError,
  NotFoundError,
  UnauthorizedError,
  ForbiddenError,
  ConflictError
};
