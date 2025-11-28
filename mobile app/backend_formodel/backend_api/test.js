#!/usr/bin/env node

/**
 * NILM API Tester - Test the API endpoints
 * 
 * Usage:
 *   node test.js          # Run all tests
 *   node test.js health   # Run specific test
 */

import axios from 'axios';
import chalk from 'chalk';

const API_BASE_URL = process.env.API_URL || 'http://localhost:3000';
const PYTHON_SERVICE_URL = process.env.PYTHON_URL || 'http://localhost:5000';

// Colors for output
const success = chalk.green;
const error = chalk.red;
const info = chalk.blue;
const warn = chalk.yellow;

// Test utilities
async function test(name, fn) {
  try {
    console.log(`\n${info('→')} Testing: ${name}`);
    await fn();
    console.log(`${success('✓')} ${name} passed`);
    return true;
  } catch (err) {
    console.log(`${error('✗')} ${name} failed`);
    console.log(`  Error: ${err.message}`);
    return false;
  }
}

// Generate test data
function generateAggregateSequence(length = 288) {
  const seq = [];
  for (let i = 0; i < length; i++) {
    // Simulate daily load curve
    const hour = (i / 12) % 24; // Convert sample index to hour
    const baseLoad = 200;
    const peakLoad = 150 * Math.sin(Math.PI * (hour - 6) / 12) ** 2;
    const noise = (Math.random() - 0.5) * 20;
    seq.push(Math.max(50, baseLoad + peakLoad + noise));
  }
  return seq;
}

// Tests
let passed = 0;
let failed = 0;

async function runTests() {
  console.log(info(`\n╔════════════════════════════════════════╗`));
  console.log(info(`║    NILM Backend API - Test Suite      ║`));
  console.log(info(`╚════════════════════════════════════════╝`));
  
  console.log(`\nAPI URL: ${info(API_BASE_URL)}`);
  console.log(`Python Service: ${info(PYTHON_SERVICE_URL)}`);

  // Test 1: API Health Check
  if (await test('API Health Check', async () => {
    const response = await axios.get(`${API_BASE_URL}/api/health`);
    if (response.status !== 200 || response.data.status !== 'healthy') {
      throw new Error('API not healthy');
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 2: API Status
  if (await test('API Status Endpoint', async () => {
    const response = await axios.get(`${API_BASE_URL}/api/status`);
    if (response.status !== 200 || !response.data.services) {
      throw new Error('Invalid status response');
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 3: Python Service Health
  if (await test('Python Service Health', async () => {
    const response = await axios.get(`${PYTHON_SERVICE_URL}/health`);
    if (response.status !== 200) {
      throw new Error('Python service not healthy');
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 4: Valid Prediction Request
  if (await test('Valid Prediction Request', async () => {
    const sequence = generateAggregateSequence(288);
    const response = await axios.post(`${API_BASE_URL}/api/predict`, {
      request_id: 'test_valid_001',
      aggregate_sequence: sequence,
    });

    if (response.status !== 200 || response.data.status !== 'success') {
      throw new Error('Prediction failed');
    }

    const { predictions } = response.data;
    if (!predictions.EVSE || !predictions.PV || !predictions.CS || !predictions.CHP || !predictions.BA) {
      throw new Error('Missing appliance predictions');
    }

    console.log(`    Predictions: EVSE=${predictions.EVSE.toFixed(2)}, PV=${predictions.PV.toFixed(2)}, CS=${predictions.CS.toFixed(2)}`);
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 5: Missing aggregate_sequence
  if (await test('Error Handling - Missing Field', async () => {
    try {
      await axios.post(`${API_BASE_URL}/api/predict`, {
        request_id: 'test_missing_001',
      });
      throw new Error('Should have returned 400 error');
    } catch (err) {
      if (err.response?.status !== 400) {
        throw new Error(`Expected 400, got ${err.response?.status}`);
      }
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 6: Invalid sequence length
  if (await test('Error Handling - Invalid Length', async () => {
    try {
      await axios.post(`${API_BASE_URL}/api/predict`, {
        request_id: 'test_length_001',
        aggregate_sequence: [150.5, 152.1, 148.9], // Only 3 values
      });
      throw new Error('Should have returned 400 error');
    } catch (err) {
      if (err.response?.status !== 400) {
        throw new Error(`Expected 400, got ${err.response?.status}`);
      }
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 7: Non-finite values
  if (await test('Error Handling - Non-finite Values', async () => {
    try {
      const sequence = generateAggregateSequence(288);
      sequence[100] = NaN;
      
      await axios.post(`${API_BASE_URL}/api/predict`, {
        request_id: 'test_nan_001',
        aggregate_sequence: sequence,
      });
      throw new Error('Should have returned 400 error');
    } catch (err) {
      if (err.response?.status !== 400) {
        throw new Error(`Expected 400, got ${err.response?.status}`);
      }
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 8: Root endpoint
  if (await test('Root Endpoint', async () => {
    const response = await axios.get(API_BASE_URL);
    if (response.status !== 200 || !response.data.endpoints) {
      throw new Error('Root endpoint failed');
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 9: Configuration endpoint (development only)
  if (await test('Configuration Endpoint', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/config`);
      if (response.status !== 200 || !response.data.model) {
        throw new Error('Config endpoint failed');
      }
    } catch (err) {
      // Expected to fail in production (403)
      if (err.response?.status === 403) {
        // This is expected in production
        console.log(`    (Disabled in production)`);
        return;
      }
      throw err;
    }
  })) {
    passed++;
  } else {
    failed++;
  }

  // Test 10: Multiple requests
  if (await test('Multiple Sequential Requests', async () => {
    for (let i = 0; i < 3; i++) {
      const sequence = generateAggregateSequence(288);
      const response = await axios.post(`${API_BASE_URL}/api/predict`, {
        request_id: `test_multi_${i}`,
        aggregate_sequence: sequence,
      });

      if (response.status !== 200 || response.data.status !== 'success') {
        throw new Error(`Request ${i} failed`);
      }
    }
    console.log(`    Completed 3 sequential requests`);
  })) {
    passed++;
  } else {
    failed++;
  }

  // Summary
  console.log(`\n${info('╔════════════════════════════════════════╗')}`);
  console.log(`${info('║')}  Test Results:                         ${info('║')}`);
  console.log(`${info('║')}  ${success(`✓ Passed: ${passed}`)}${' '.repeat(24 - String(passed).length)}${info('║')}`);
  console.log(`${info('║')}  ${failed > 0 ? error(`✗ Failed: ${failed}`) : success(`✗ Failed: ${failed}`)}${' '.repeat(24 - String(failed).length)}${info('║')}`);
  console.log(`${info('║')}  ${info(`Total: ${passed + failed}`)}${' '.repeat(28 - String(passed + failed).length)}${info('║')}`);
  console.log(`${info('╚════════════════════════════════════════╝')}`);

  process.exit(failed > 0 ? 1 : 0);
}

// Run tests
runTests().catch(err => {
  console.error(error('Fatal error:'), err.message);
  process.exit(1);
});
