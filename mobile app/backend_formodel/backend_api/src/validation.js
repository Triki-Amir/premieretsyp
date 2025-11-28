import Joi from 'joi';

/**
 * Request payload schema for NILM prediction
 */
const predictionRequestSchema = Joi.object({
  request_id: Joi.string()
    .max(255)
    .optional()
    .description('Optional tracking ID for the request'),
  
  timestamp: Joi.string()
    .isoDate()
    .optional()
    .description('ISO8601 timestamp for reference'),
  
  aggregate_sequence: Joi.array()
    .items(Joi.number().required())
    .length(288)
    .required()
    .description('Array of 288 aggregate power readings (24 hours at 5-min intervals)'),
});

/**
 * Validate incoming prediction request
 * @param {object} data - Request payload
 * @returns {object} - {valid: boolean, error?: string, value?: object}
 */
export function validatePredictionRequest(data) {
  const { error, value } = predictionRequestSchema.validate(data, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const messages = error.details.map(d => d.message).join('; ');
    return {
      valid: false,
      error: `Validation failed: ${messages}`,
    };
  }

  // Additional validation checks
  const { aggregate_sequence } = value;

  // Check for NaN values
  if (aggregate_sequence.some(val => !Number.isFinite(val))) {
    return {
      valid: false,
      error: 'aggregate_sequence contains non-finite values (NaN or Infinity)',
    };
  }

  // Check for reasonable value ranges (optional, can be adjusted)
  const hasExtreme = aggregate_sequence.some(val => Math.abs(val) > 10000);
  if (hasExtreme) {
    console.warn('⚠️ Warning: aggregate_sequence contains extreme values. Ensure units are consistent.');
  }

  return {
    valid: true,
    value,
  };
}

export default { validatePredictionRequest };
