const { createLogger, transports, format } = require('winston');
const config = require('../config');

const logger = createLogger({
  level: config.logLevel || 'info',
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.splat(),
    format.json()
  ),
  transports: [new transports.Console()],
});

module.exports = logger;
