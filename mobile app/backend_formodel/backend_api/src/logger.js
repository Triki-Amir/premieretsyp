import config from '../config/config.js';

const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
};

const currentLevel = LOG_LEVELS[config.logging.level] || LOG_LEVELS.info;

const logger = {
  error: (message, ...args) => {
    if (currentLevel >= LOG_LEVELS.error) {
      console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, ...args);
    }
  },

  warn: (message, ...args) => {
    if (currentLevel >= LOG_LEVELS.warn) {
      console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...args);
    }
  },

  info: (message, ...args) => {
    if (currentLevel >= LOG_LEVELS.info) {
      console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...args);
    }
  },

  debug: (message, ...args) => {
    if (currentLevel >= LOG_LEVELS.debug) {
      console.log(`[DEBUG] ${new Date().toISOString()} - ${message}`, ...args);
    }
  },
};

export default logger;
