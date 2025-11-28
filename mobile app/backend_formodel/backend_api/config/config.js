import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const config = {
  // Express Server Configuration
  express: {
    port: process.env.EXPRESS_PORT || 3000,
    nodeEnv: process.env.NODE_ENV || 'development',
    corsOrigin: process.env.CORS_ORIGIN || '*',
  },

  // Flask Python Service Configuration
  flaskService: {
    url: process.env.FLASK_SERVICE_URL || 'http://localhost:5000',
    port: process.env.FLASK_PORT || 5000,
    inferenceEndpoint: '/predict',
    timeout: 30000, // 30 seconds
  },

  // Model Configuration
  model: {
    name: process.env.MODEL_NAME || 'TCN_best.pth',
    path: process.env.MODEL_PATH || join(__dirname, '../../NILM_SIDED/saved_models'),
    inputLength: 288, // 24 hours at 5-minute intervals
    inputResolution: '5min', // 5-minute intervals
    appliances: ['EVSE', 'PV', 'CS', 'CHP', 'BA'],
    inputSize: 1,
    outputSize: 5,
  },

  // API Configuration
  api: {
    requestTimeout: 60000, // 60 seconds
    maxRequestBodySize: '10mb',
    validateInput: true,
    logRequests: true,
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: 'combined',
  },

  // Validation thresholds
  validation: {
    minAggregateValue: -1000, // kW or MW
    maxAggregateValue: 1000, // kW or MW
    nanTolerance: 0, // Do not allow NaN values
  },
};

export default config;
