import express from 'express';
import cors from 'cors';
import config from '../config/config.js';
import routes from './routes.js';
import logger from './logger.js';
import pythonClient from './pythonClient.js';

const app = express();
const PORT = config.express.port;
const NODE_ENV = config.express.nodeEnv;

// Middleware
app.use(express.json({ limit: config.api.maxRequestBodySize }));
app.use(express.urlencoded({ limit: config.api.maxRequestBodySize, extended: true }));
app.use(cors({ origin: config.express.corsOrigin }));

// Request logging middleware
if (config.api.logRequests) {
  app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`);
    next();
  });
}

// Routes
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'NILM Model API Server',
    version: '1.0.0',
    endpoints: {
      health: 'GET /api/health',
      status: 'GET /api/status',
      predict: 'POST /api/predict',
      config: 'GET /api/config (development only)',
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
  });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err.message);
  res.status(500).json({
    error: 'Internal server error',
    message: NODE_ENV === 'development' ? err.message : 'An unexpected error occurred',
  });
});

// Start server
async function startServer() {
  logger.info(`🚀 Starting NILM API Server (Node ${NODE_ENV})`);
  logger.info(`📊 Model: ${config.model.name}`);
  logger.info(`🔗 Flask Service URL: ${config.flaskService.url}`);

  // Check Python service health
  logger.info('🏥 Checking Python service health...');
  const pythonHealthy = await pythonClient.healthCheck();
  
  if (pythonHealthy) {
    logger.info('✅ Python service is healthy');
  } else {
    logger.warn('⚠️  Python service is not responding. The API will start, but predictions will fail.');
    logger.warn('    Make sure to run the Python Flask service before making requests.');
  }

  app.listen(PORT, () => {
    logger.info(`✅ Express API listening on port ${PORT}`);
    logger.info(`📍 Access at http://localhost:${PORT}`);
    logger.info(`📝 API docs: http://localhost:${PORT}/api/health`);
  });
}

startServer().catch(err => {
  logger.error('Failed to start server:', err.message);
  process.exit(1);
});
