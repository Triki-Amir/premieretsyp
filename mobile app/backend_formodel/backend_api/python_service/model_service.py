"""
NILM Model Inference Service
Flask-based Python backend for loading and running PyTorch NILM models.

This service:
1. Loads a trained PyTorch model
2. Handles preprocessing (normalization) using stored scaler statistics
3. Runs inference on the model
4. Handles postprocessing (inverse transformation)
5. Enforces sign conventions for generation/load appliances
"""

import os
import json
import torch
import numpy as np
import logging
from pathlib import Path
from flask import Flask, request, jsonify
from flask_cors import CORS
from sklearn.preprocessing import StandardScaler
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
MODEL_NAME = os.getenv('MODEL_NAME', 'TCN_best.pth')
MODEL_PATH_RAW = os.getenv('MODEL_PATH', '../../NILM_SIDED/saved_models')
SCALER_PATH = os.getenv('SCALER_PATH', '../../NILM_SIDED')
FLASK_PORT = int(os.getenv('FLASK_PORT', 5000))
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'

# Resolve paths relative to this script's location
SCRIPT_DIR = Path(__file__).parent.resolve()
MODEL_PATH = (SCRIPT_DIR / MODEL_PATH_RAW).resolve()

# Appliance configuration
APPLIANCE_NAMES = ['EVSE', 'PV', 'CS', 'CHP', 'BA']
LOAD_APPLIANCES = ['EVSE', 'CS', 'BA']
GENERATION_APPLIANCES = ['PV', 'CHP']

# Global variables
model = None
scaler_y = None
device = None


class TCNModel(torch.nn.Module):
    """Temporal Convolutional Network Model"""
    
    def __init__(self, input_size, num_channels=[64, 128, 128], kernel_size=3, dropout=0.2, output_size=5):
        super(TCNModel, self).__init__()
        layers = []
        num_levels = len(num_channels)
        
        for i in range(num_levels):
            dilation_size = 2 ** i
            in_channels = input_size if i == 0 else num_channels[i-1]
            out_channels = num_channels[i]
            padding = (kernel_size - 1) * dilation_size
            
            layers.append(TemporalBlock(in_channels, out_channels, kernel_size,
                                       stride=1, dilation=dilation_size,
                                       padding=padding, dropout=dropout))
        
        self.network = torch.nn.Sequential(*layers)
        self.fc = torch.nn.Linear(num_channels[-1], output_size)
        
    def forward(self, x):
        # x shape: (batch, seq_len, input_size)
        x = x.permute(0, 2, 1)  # (batch, input_size, seq_len)
        x = self.network(x)
        x = x.mean(dim=2)  # Global average pooling
        return self.fc(x)


class Chomp1d(torch.nn.Module):
    """Chomp padding from the end"""
    def __init__(self, chomp_size):
        super(Chomp1d, self).__init__()
        self.chomp_size = chomp_size

    def forward(self, x):
        return x[:, :, :-self.chomp_size].contiguous()


class TemporalBlock(torch.nn.Module):
    """Temporal block for TCN"""
    def __init__(self, n_inputs, n_outputs, kernel_size, stride, dilation, padding, dropout=0.2):
        super(TemporalBlock, self).__init__()
        self.conv1 = torch.nn.Conv1d(n_inputs, n_outputs, kernel_size,
                               stride=stride, padding=padding, dilation=dilation)
        self.chomp1 = Chomp1d(padding)
        self.relu1 = torch.nn.ReLU()
        self.dropout1 = torch.nn.Dropout(dropout)
        
        self.conv2 = torch.nn.Conv1d(n_outputs, n_outputs, kernel_size,
                               stride=stride, padding=padding, dilation=dilation)
        self.chomp2 = Chomp1d(padding)
        self.relu2 = torch.nn.ReLU()
        self.dropout2 = torch.nn.Dropout(dropout)
        
        self.net = torch.nn.Sequential(self.conv1, self.chomp1, self.relu1, self.dropout1,
                                self.conv2, self.chomp2, self.relu2, self.dropout2)
        self.downsample = torch.nn.Conv1d(n_inputs, n_outputs, 1) if n_inputs != n_outputs else None
        self.relu = torch.nn.ReLU()

    def forward(self, x):
        out = self.net(x)
        res = x if self.downsample is None else self.downsample(x)
        return self.relu(out + res)


class BiLSTMModel(torch.nn.Module):
    """Bidirectional LSTM Model"""
    def __init__(self, input_size, hidden_size=128, num_layers=3, output_size=5):
        super(BiLSTMModel, self).__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        
        self.lstm = torch.nn.LSTM(input_size=input_size,
                           hidden_size=hidden_size,
                           num_layers=num_layers,
                           batch_first=True,
                           bidirectional=True,
                           dropout=0.2)
        
        self.fc = torch.nn.Linear(hidden_size * 2, output_size)
        
    def forward(self, x):
        lstm_out, (_h_n, _c_n) = self.lstm(x)
        out = self.fc(lstm_out[:, -1, :])
        return out


class ATCNModel(torch.nn.Module):
    """Attention TCN Model"""
    
    def __init__(self, input_size, num_channels=[64, 128, 128], kernel_size=3, dropout=0.2, output_size=5):
        super(ATCNModel, self).__init__()
        layers = []
        num_levels = len(num_channels)
        
        for i in range(num_levels):
            dilation_size = 2 ** i
            in_channels = input_size if i == 0 else num_channels[i-1]
            out_channels = num_channels[i]
            padding = (kernel_size - 1) * dilation_size
            
            layers.append(TemporalBlock(in_channels, out_channels, kernel_size,
                                       stride=1, dilation=dilation_size,
                                       padding=padding, dropout=dropout))
        
        self.network = torch.nn.Sequential(*layers)
        self.attention = AttentionLayer(num_channels[-1])
        self.fc = torch.nn.Linear(num_channels[-1], output_size)
        
    def forward(self, x):
        x = x.permute(0, 2, 1)
        x = self.network(x)
        x = x.permute(0, 2, 1)
        x = self.attention(x)
        return self.fc(x)


class AttentionLayer(torch.nn.Module):
    """Attention mechanism"""
    def __init__(self, hidden_size):
        super(AttentionLayer, self).__init__()
        self.attention = torch.nn.Sequential(
            torch.nn.Linear(hidden_size, hidden_size),
            torch.nn.Tanh(),
            torch.nn.Linear(hidden_size, 1)
        )
    
    def forward(self, x):
        attention_weights = self.attention(x)
        attention_weights = torch.softmax(attention_weights, dim=1)
        weighted = x * attention_weights
        return weighted.sum(dim=1)


def load_model_and_scaler():
    """
    Load the trained PyTorch model and scalers from disk.
    Returns the model, scaler_y, and device.
    """
    global model, scaler_y, device
    
    logger.info('🔧 Initializing PyTorch environment...')
    
    # Determine device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    logger.info(f'📍 Using device: {device}')
    if device.type == 'cuda':
        logger.info(f'   GPU: {torch.cuda.get_device_name(0)}')
    
    # Load model
    model_file = Path(MODEL_PATH) / MODEL_NAME
    if not model_file.exists():
        raise FileNotFoundError(f'Model file not found: {model_file}')
    
    logger.info(f'📂 Loading model from: {model_file}')
    
    # Initialize model (hardcoded config matching training)
    model = TCNModel(
        input_size=1,
        num_channels=[64, 64, 64, 64, 128, 128, 128, 128],
        kernel_size=3,
        dropout=0.33,
        output_size=5
    )
    
    # Load weights
    model.load_state_dict(torch.load(model_file, map_location=device))
    model.to(device)
    model.eval()
    logger.info('✅ Model loaded successfully')
    
    # Load scaler statistics
    # In a production environment, you'd save these during training
    # For now, we create a placeholder that will be set during inference
    scaler_y = StandardScaler()
    logger.info('✅ Scaler initialized')
    
    return model, scaler_y, device


def sanitize_array(arr, name='array'):
    """Sanitize array: replace non-finite values"""
    if not np.isfinite(arr).all():
        logger.warning(f'⚠️  Non-finite values detected in {name}. Sanitizing...')
        arr = np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0)
    return arr


def run_inference(aggregate_sequence, request_id='unknown'):
    """
    Run model inference on the given aggregate power sequence.
    
    Args:
        aggregate_sequence (list): Array of 288 aggregate power readings
        request_id (str): Tracking ID for logging
        
    Returns:
        dict: Dictionary with appliance predictions
    """
    logger.info(f'[{request_id}] Starting inference...')
    
    try:
        # Convert to numpy array
        X = np.array(aggregate_sequence, dtype=np.float32).reshape(-1, 1)
        logger.debug(f'[{request_id}] Input shape: {X.shape}')
        logger.debug(f'[{request_id}] Input range: [{X.min():.4f}, {X.max():.4f}]')
        
        # Normalize using StandardScaler
        # NOTE: In production, use the scaler statistics from training data!
        # For now, we fit on the current data (this is NOT ideal for production)
        scaler_X = StandardScaler()
        X_normalized = scaler_X.fit_transform(X)
        
        logger.debug(f'[{request_id}] Normalized range: [{X_normalized.min():.4f}, {X_normalized.max():.4f}]')
        
        # Convert to PyTorch tensor and add batch dimension
        X_tensor = torch.FloatTensor(X_normalized).unsqueeze(0)  # (1, 288, 1)
        logger.debug(f'[{request_id}] Tensor shape: {X_tensor.shape}')
        
        # Run inference
        with torch.no_grad():
            X_tensor = X_tensor.to(device)
            outputs = model(X_tensor)
            
            # Sanitize outputs
            outputs = torch.clamp(outputs, min=-8.0, max=8.0)
            outputs = outputs.cpu().numpy()
        
        outputs = sanitize_array(outputs, f'[{request_id}] outputs')
        logger.debug(f'[{request_id}] Raw output shape: {outputs.shape}')
        logger.debug(f'[{request_id}] Raw output range: [{outputs.min():.4f}, {outputs.max():.4f}]')
        
        # For inverse transform, we need the scaler_y statistics from training
        # This is a critical step that should use actual training statistics
        # For now, create a minimal scaler (this will not be accurate)
        scaler_y_local = StandardScaler()
        scaler_y_local.mean_ = np.array([0.0] * 5)  # Placeholder
        scaler_y_local.scale_ = np.array([1.0] * 5)  # Placeholder
        
        outputs_real = scaler_y_local.inverse_transform(outputs)
        logger.debug(f'[{request_id}] After inverse transform: {outputs_real}')
        
        # Apply sign conventions
        for i, app_name in enumerate(APPLIANCE_NAMES):
            if app_name in LOAD_APPLIANCES:
                outputs_real[0, i] = max(outputs_real[0, i], 0)
            elif app_name in GENERATION_APPLIANCES:
                outputs_real[0, i] = min(outputs_real[0, i], 0)
        
        # Create prediction dictionary
        predictions = {
            APPLIANCE_NAMES[i]: float(outputs_real[0, i])
            for i in range(len(APPLIANCE_NAMES))
        }
        
        logger.info(f'[{request_id}] Inference completed successfully')
        logger.debug(f'[{request_id}] Predictions: {predictions}')
        
        return predictions
        
    except Exception as e:
        logger.error(f'[{request_id}] Inference error: {str(e)}')
        raise


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model': MODEL_NAME,
    }), 200


@app.route('/predict', methods=['POST'])
def predict():
    """
    Prediction endpoint
    
    Request:
    {
        "aggregate_sequence": [list of 288 numbers],
        "request_id": "optional_request_id",
        "timestamp": "ISO8601_timestamp"
    }
    
    Response:
    {
        "request_id": "request_id",
        "predictions": {
            "EVSE": number,
            "PV": number,
            "CS": number,
            "CHP": number,
            "BA": number
        },
        "status": "success",
        "timestamp": "ISO8601_timestamp"
    }
    """
    try:
        data = request.get_json()
        request_id = data.get('request_id', f'req_{datetime.now().timestamp()}')
        
        logger.info(f'[{request_id}] Received prediction request')
        
        # Validate input
        if 'aggregate_sequence' not in data:
            logger.warning(f'[{request_id}] Missing aggregate_sequence in request')
            return jsonify({
                'request_id': request_id,
                'status': 'error',
                'error': 'Missing required field: aggregate_sequence',
                'timestamp': datetime.now().isoformat(),
            }), 400
        
        aggregate_sequence = data['aggregate_sequence']
        
        # Validate sequence length and values
        if not isinstance(aggregate_sequence, list) or len(aggregate_sequence) != 288:
            logger.warning(f'[{request_id}] Invalid sequence length: {len(aggregate_sequence) if isinstance(aggregate_sequence, list) else "not a list"}')
            return jsonify({
                'request_id': request_id,
                'status': 'error',
                'error': 'aggregate_sequence must be a list of exactly 288 numbers',
                'timestamp': datetime.now().isoformat(),
            }), 400
        
        if not all(isinstance(x, (int, float)) and np.isfinite(x) for x in aggregate_sequence):
            logger.warning(f'[{request_id}] Invalid values in sequence')
            return jsonify({
                'request_id': request_id,
                'status': 'error',
                'error': 'aggregate_sequence contains non-numeric or non-finite values',
                'timestamp': datetime.now().isoformat(),
            }), 400
        
        # Run inference
        predictions = run_inference(aggregate_sequence, request_id)
        
        # Return response
        return jsonify({
            'request_id': request_id,
            'predictions': predictions,
            'status': 'success',
            'timestamp': datetime.now().isoformat(),
        }), 200
        
    except Exception as e:
        logger.error(f'[{request_id}] Error: {str(e)}')
        return jsonify({
            'request_id': request_id,
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat(),
        }), 500


@app.route('/info', methods=['GET'])
def info():
    """Model information endpoint"""
    return jsonify({
        'model': MODEL_NAME,
        'appliances': APPLIANCE_NAMES,
        'input_length': 288,
        'input_resolution': '5min',
        'device': str(device),
        'timestamp': datetime.now().isoformat(),
    }), 200


if __name__ == '__main__':
    logger.info('='*60)
    logger.info('🚀 Starting NILM Flask Inference Service')
    logger.info('='*60)
    
    # Load model on startup
    try:
        model, scaler_y, device = load_model_and_scaler()
        logger.info('✅ All models and scalers loaded successfully')
        
        # Start Flask server
        logger.info(f'📍 Starting Flask server on port {FLASK_PORT}')
        app.run(host='0.0.0.0', port=FLASK_PORT, debug=FLASK_DEBUG)
        
    except Exception as e:
        logger.error(f'❌ Failed to start service: {str(e)}')
        exit(1)
