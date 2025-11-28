import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import config from '../config/config.js';
import { validatePredictionRequest } from './validation.js';
import pythonClient from './pythonClient.js';
import logger from './logger.js';

const router = express.Router();

/**
 * Health Check Endpoint
 * GET /api/health
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

/**
 * Model Status Endpoint
 * GET /api/status
 */
router.get('/status', async (req, res) => {
  try {
    const pythonServiceHealthy = await pythonClient.healthCheck();
    
    res.status(200).json({
      status: pythonServiceHealthy ? 'operational' : 'degraded',
      timestamp: new Date().toISOString(),
      services: {
        expressAPI: 'operational',
        pythonService: pythonServiceHealthy ? 'operational' : 'unavailable',
      },
      model: {
        name: config.model.name,
        appliances: config.model.appliances,
        inputLength: config.model.inputLength,
        inputResolution: config.model.inputResolution,
      },
    });
  } catch (error) {
    logger.error('Status check error:', error.message);
    res.status(500).json({
      status: 'error',
      message: error.message,
    });
  }
});

/**
 * NILM Prediction Endpoint
 * POST /api/predict
 * 
 * Request body:
 * {
 *   "aggregate_sequence": [number, ...], // 288 values
 *   "request_id": "string (optional)",
 *   "timestamp": "ISO8601 (optional)"
 * }
 * 
 * Response:
 * {
 *   "request_id": "string",
 *   "timestamp": "ISO8601",
 *   "predictions": {
 *     "EVSE": number,
 *     "PV": number,
 *     "CS": number,
 *     "CHP": number,
 *     "BA": number
 *   },
 *   "status": "success"
 * }
 */
router.post('/predict', async (req, res) => {
  const startTime = Date.now();
  const requestId = req.body.request_id || uuidv4();

  try {
    logger.info(`[${requestId}] Received prediction request`);

    // Validate input
    const validation = validatePredictionRequest(req.body);
    if (!validation.valid) {
      logger.warn(`[${requestId}] Validation failed: ${validation.error}`);
      return res.status(400).json({
        request_id: requestId,
        status: 'error',
        error: validation.error,
        timestamp: new Date().toISOString(),
      });
    }

    const { aggregate_sequence, timestamp } = validation.value;
    logger.debug(`[${requestId}] Input validated. Sequence length: ${aggregate_sequence.length}`);
    logger.debug(`[${requestId}] Input range: [${Math.min(...aggregate_sequence).toFixed(2)}, ${Math.max(...aggregate_sequence).toFixed(2)}]`);

    // Call Python model service
    logger.debug(`[${requestId}] Calling Python model service...`);
    const modelResponse = await pythonClient.predict(aggregate_sequence, {
      request_id: requestId,
      timestamp: timestamp || new Date().toISOString(),
    });

    const elapsedTime = Date.now() - startTime;
    logger.info(`[${requestId}] Prediction successful (${elapsedTime}ms)`);
    logger.debug(`[${requestId}] Predictions:`, modelResponse.predictions);

    // Return response
    return res.status(200).json({
      request_id: requestId,
      timestamp: new Date().toISOString(),
      predictions: modelResponse.predictions,
      status: 'success',
      processingTimeMs: elapsedTime,
    });
  } catch (error) {
    const elapsedTime = Date.now() - startTime;
    logger.error(`[${requestId}] Prediction error (${elapsedTime}ms):`, error.message);

    const statusCode = error.message.includes('unavailable') ? 503 : 500;
    const errorMessage = process.env.NODE_ENV === 'development' 
      ? error.message 
      : 'An error occurred while processing your request. Please try again later.';

    return res.status(statusCode).json({
      request_id: requestId,
      timestamp: new Date().toISOString(),
      status: 'error',
      error: errorMessage,
      processingTimeMs: elapsedTime,
    });
  }
});

/**
 * Configuration Info Endpoint (for debugging)
 * GET /api/config
 */
router.get('/config', (req, res) => {
  if (process.env.NODE_ENV !== 'development') {
    return res.status(403).json({
      error: 'Configuration endpoint only available in development mode',
    });
  }

  res.status(200).json({
    model: config.model,
    api: {
      port: config.express.port,
      nodeEnv: config.express.nodeEnv,
    },
    flaskService: {
      url: config.flaskService.url,
      timeout: config.flaskService.timeout,
    },
  });
});

export default router;
