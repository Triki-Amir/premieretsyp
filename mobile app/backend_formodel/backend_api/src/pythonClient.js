import axios from 'axios';
import config from '../config/config.js';
import logger from './logger.js';

/**
 * Python Model Inference Client
 * Communicates with Flask backend for model inference
 */
class PythonModelClient {
  constructor() {
    this.baseURL = config.flaskService.url;
    this.endpoint = config.flaskService.inferenceEndpoint;
    this.timeout = config.flaskService.timeout;
    
    // Create axios instance with configuration
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: this.timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Send prediction request to Python service
   * @param {Array<number>} aggregateSequence - Array of 288 aggregate power readings
   * @param {object} options - Optional metadata (request_id, timestamp)
   * @returns {Promise<object>} - Prediction results with appliance power values
   */
  async predict(aggregateSequence, options = {}) {
    try {
      if (!Array.isArray(aggregateSequence) || aggregateSequence.length !== 288) {
        throw new Error('aggregateSequence must be an array of exactly 288 numbers');
      }

      const payload = {
        aggregate_sequence: aggregateSequence,
        request_id: options.request_id || `req_${Date.now()}`,
        timestamp: options.timestamp || new Date().toISOString(),
      };

      logger.debug(`Sending prediction request to Flask service: ${this.baseURL}${this.endpoint}`);
      logger.debug(`Payload size: ${JSON.stringify(payload).length} bytes`);

      const response = await this.client.post(this.endpoint, payload);

      logger.debug(`Received response from Flask service:`, response.status);

      // Validate response structure
      if (!response.data || response.data.status !== 'success') {
        throw new Error(`Flask service returned error: ${response.data?.error || 'Unknown error'}`);
      }

      return response.data;
    } catch (error) {
      if (error.response) {
        logger.error(`Flask service error (${error.response.status}):`, error.response.data);
        throw new Error(`Flask service error: ${error.response.data?.error || error.message}`);
      } else if (error.code === 'ECONNREFUSED') {
        logger.error('Cannot connect to Flask service. Is it running?');
        throw new Error('Model service unavailable. Please ensure Python service is running.');
      } else if (error.code === 'ENOTFOUND') {
        logger.error(`Cannot resolve Flask service URL: ${this.baseURL}`);
        throw new Error(`Invalid service URL: ${this.baseURL}`);
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET') {
        logger.error(`Flask service timeout or connection reset: ${error.message}`);
        throw new Error('Model service timeout. Request took too long.');
      } else {
        logger.error(`Error communicating with Flask service:`, error.message);
        throw error;
      }
    }
  }

  /**
   * Health check for Flask service
   * @returns {Promise<boolean>} - True if service is healthy
   */
  async healthCheck() {
    try {
      const response = await this.client.get('/health', {
        timeout: 5000,
      });
      return response.status === 200;
    } catch (error) {
      logger.warn(`Health check failed: ${error.message}`);
      return false;
    }
  }
}

export default new PythonModelClient();
