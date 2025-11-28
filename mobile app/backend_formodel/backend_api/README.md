# NILM Backend API - Setup & Documentation

This is a complete Express.js + Python Flask backend for serving the NILM (Non-Intrusive Load Monitoring) model as an API.

## 📋 Project Structure

```
backend_api/
├── src/
│   ├── server.js           # Express server entry point
│   ├── routes.js           # API route definitions
│   ├── pythonClient.js     # Client for Python service communication
│   ├── validation.js       # Request validation schemas
│   └── logger.js           # Logging utility
├── python_service/
│   ├── model_service.py    # Flask server for model inference
│   └── requirements.txt     # Python dependencies
├── config/
│   └── config.js           # Configuration settings
├── package.json            # Node.js dependencies
├── .env.example            # Environment variables template
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** (v16+)
- **Python** (3.9+)
- **CUDA toolkit** (optional, for GPU support)

### 1. Install Dependencies

#### Node.js Dependencies
```bash
cd backend_api
npm install
```

#### Python Dependencies
```bash
cd python_service
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and adjust settings:
```bash
cp .env.example .env
```

Edit `.env`:
```env
NODE_ENV=development
EXPRESS_PORT=3000
FLASK_SERVICE_URL=http://localhost:5000
FLASK_PORT=5000
MODEL_NAME=TCN_best.pth
MODEL_PATH=../NILM_SIDED/saved_models
```

### 3. Start Services

**Terminal 1: Python Flask Service**
```bash
cd python_service
# Activate virtual environment first
python model_service.py
```

Expected output:
```
✅ Model loaded successfully
📍 Starting Flask server on port 5000
```

**Terminal 2: Express API Server**
```bash
npm start
```

Expected output:
```
✅ Express API listening on port 3000
📍 Access at http://localhost:3000
```

## 📡 API Endpoints

### 1. Health Check
```
GET /api/health
```
Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-23T14:30:00Z",
  "version": "1.0.0"
}
```

### 2. Service Status
```
GET /api/status
```
Response:
```json
{
  "status": "operational",
  "timestamp": "2025-11-23T14:30:00Z",
  "services": {
    "expressAPI": "operational",
    "pythonService": "operational"
  },
  "model": {
    "name": "TCN_best.pth",
    "appliances": ["EVSE", "PV", "CS", "CHP", "BA"],
    "inputLength": 288,
    "inputResolution": "5min"
  }
}
```

### 3. NILM Prediction (Main Endpoint)
```
POST /api/predict
Content-Type: application/json
```

**Request:**
```json
{
  "request_id": "req_12345",
  "timestamp": "2025-11-23T14:30:00Z",
  "aggregate_sequence": [150.5, 152.1, 148.9, ..., 160.2]
}
```

**Response (Success):**
```json
{
  "request_id": "req_12345",
  "timestamp": "2025-11-23T14:30:00Z",
  "predictions": {
    "EVSE": 45.2,
    "PV": -12.5,
    "CS": 22.1,
    "CHP": 0.0,
    "BA": 5.3
  },
  "status": "success",
  "processingTimeMs": 125
}
```

**Response (Error):**
```json
{
  "request_id": "req_12345",
  "timestamp": "2025-11-23T14:30:00Z",
  "status": "error",
  "error": "aggregate_sequence must be an array of exactly 288 numbers",
  "processingTimeMs": 5
}
```

### Input Constraints
- `aggregate_sequence`: **Must be an array of exactly 288 floating-point numbers**
  - Represents 24 hours at 5-minute intervals
  - Index 0 = oldest reading (T - 24h)
  - Index 287 = most recent reading (Current time T)
- `request_id`: Optional string for tracking (generates UUID if not provided)
- `timestamp`: Optional ISO8601 timestamp (defaults to current time)

### Output Fields
| Field | Type | Description |
|-------|------|-------------|
| `EVSE` | number | Electric Vehicle Supply Equipment power (kW/MW) |
| `PV` | number | Photovoltaic generation (typically negative) |
| `CS` | number | Cooling System power |
| `CHP` | number | Combined Heat and Power generation |
| `BA` | number | Battery / Building Automation power |

**Sign Conventions:**
- **Loads** (EVSE, CS, BA): Positive values = consumption
- **Generation** (PV, CHP): Negative values = generation

## 🔧 Configuration

Edit `config/config.js` to customize:

```javascript
config = {
  // Express server
  express: {
    port: 3000,
    nodeEnv: 'development',
    corsOrigin: '*',
  },

  // Flask service
  flaskService: {
    url: 'http://localhost:5000',
    timeout: 30000, // ms
  },

  // Model
  model: {
    name: 'TCN_best.pth',
    path: './saved_models',
    appliances: ['EVSE', 'PV', 'CS', 'CHP', 'BA'],
  },

  // API validation
  api: {
    requestTimeout: 60000, // ms
    maxRequestBodySize: '10mb',
  },
}
```

## 📊 Testing the API

### Using cURL
```bash
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "test_001",
    "aggregate_sequence": [150.5, 152.1, 148.9, 155.0, 160.2, ..., 155.8]
  }'
```

### Using JavaScript/Node.js
```javascript
const response = await fetch('http://localhost:3000/api/predict', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    request_id: 'test_001',
    aggregate_sequence: [150.5, 152.1, 148.9, ...] // 288 values
  })
});
const result = await response.json();
console.log(result.predictions);
```

### Using Python
```python
import requests
import numpy as np

# Generate or load aggregate sequence (288 values)
aggregate_seq = np.random.rand(288).tolist()

response = requests.post('http://localhost:3000/api/predict', json={
    'request_id': 'test_001',
    'aggregate_sequence': aggregate_seq
})

predictions = response.json()['predictions']
print(f"EVSE: {predictions['EVSE']} kW")
print(f"PV:   {predictions['PV']} kW")
print(f"CS:   {predictions['CS']} kW")
print(f"CHP:  {predictions['CHP']} kW")
print(f"BA:   {predictions['BA']} kW")
```

## 🔄 How It Works

### Request Flow
```
Mobile App / Frontend
    ↓
  [POST /api/predict]
    ↓
Express API Server (Node.js)
    ├─ Validates input (schema, array length, values)
    ├─ Generates request_id (if needed)
    └─ Forwards to Python service
    ↓
Flask Service (Python)
    ├─ Receives normalized aggregate sequence
    ├─ Standardizes input using StandardScaler
    ├─ Runs PyTorch model inference
    ├─ Inverse transforms predictions
    ├─ Applies sign conventions
    └─ Returns predictions
    ↓
Express API Server (Node.js)
    ├─ Receives predictions from Flask
    └─ Returns JSON response to client
    ↓
Mobile App / Frontend (displays results)
```

### Data Preprocessing (Flask)
1. **Input Validation**: Check array length = 288, all values finite
2. **Normalization**: Apply Z-score scaling (mean=0, std=1)
3. **Tensor Conversion**: Convert to PyTorch tensor with shape (1, 288, 1)
4. **Model Inference**: Run through TCN/BiLSTM/ATCN model
5. **Inverse Transform**: Convert standardized predictions back to real units
6. **Sign Convention**: Enforce load/generation constraints

## ⚙️ Model Selection

The backend currently loads `TCN_best.pth`. To use a different model:

### 1. Update `.env`
```env
MODEL_NAME=BiLSTM_best.pth
# or
MODEL_NAME=ATCN_best.pth
```

### 2. Update Python Service (if model architecture differs)

Edit `python_service/model_service.py`:
```python
# Change model initialization based on selected model
if MODEL_NAME == 'TCN_best.pth':
    model = TCNModel(...)
elif MODEL_NAME == 'BiLSTM_best.pth':
    model = BiLSTMModel(...)
elif MODEL_NAME == 'ATCN_best.pth':
    model = ATCNModel(...)
```

### Available Models
| Model | File | Architecture | Accuracy |
|-------|------|--------------|----------|
| TCN | `TCN_best.pth` | Temporal Convolutional Network | Good spike capture |
| BiLSTM | `BiLSTM_best.pth` | Bidirectional LSTM | Smooth predictions |
| ATCN | `ATCN_best.pth` | Attention TCN | Best for complex patterns |

## 🛡️ Error Handling

### Common Errors

**1. Python Service Unavailable**
```json
{
  "status": "error",
  "error": "Model service unavailable. Please ensure Python service is running.",
  "processingTimeMs": 102
}
```
**Solution**: Start Flask service in a separate terminal.

**2. Invalid Input Length**
```json
{
  "status": "error",
  "error": "Validation failed: aggregate_sequence with length X must have 288 items"
}
```
**Solution**: Ensure aggregate_sequence has exactly 288 values.

**3. Non-finite Values**
```json
{
  "status": "error",
  "error": "aggregate_sequence contains non-finite values (NaN or Infinity)"
}
```
**Solution**: Check input data for NaN/Inf values.

**4. Service Timeout**
```json
{
  "status": "error",
  "error": "Model service timeout. Request took too long."
}
```
**Solution**: Check if Flask service is responsive or increase timeout in config.

## 📈 Performance Optimization

### For Production Deployment

1. **Use PM2 or Docker** to manage processes:
```bash
# Install PM2
npm install -g pm2

# Start services
pm2 start src/server.js --name nilm-api
pm2 start python_service/model_service.py --name nilm-flask
```

2. **Enable GPU** (if available):
```bash
# Update config.js to use CUDA
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
```

3. **Cache Scaler Statistics**:
Save training scaler mean/std to JSON:
```python
# In notebook after training:
import json
scaler_stats = {
    'mean': scaler_y.mean_.tolist(),
    'scale': scaler_y.scale_.tolist()
}
with open('scaler_stats.json', 'w') as f:
    json.dump(scaler_stats, f)
```

Load in Flask service:
```python
with open('scaler_stats.json', 'r') as f:
    stats = json.load(f)
scaler_y.mean_ = np.array(stats['mean'])
scaler_y.scale_ = np.array(stats['scale'])
```

4. **Load Balancing**: Use nginx to distribute requests across multiple Flask instances.

## 🐛 Debugging

### Enable Debug Logging
```bash
# Set log level in .env
LOG_LEVEL=debug

# Or modify config/config.js
logging: {
  level: 'debug',
}
```

### Check Service Health
```bash
# Check Express API
curl http://localhost:3000/api/health

# Check Flask service
curl http://localhost:5000/health
```

### View Logs
```bash
# Node.js (console output includes timestamps and levels)
# Python (logs to console with timestamp prefix)
```

## 📚 API Contract Reference

See `../NILM_SIDED/API_CONTRACT.md` for detailed specifications.

## 🔗 Integration with Mobile App

In your Flutter app, make requests like:

```dart
final response = await http.post(
  Uri.parse('http://YOUR_SERVER:3000/api/predict'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'request_id': 'mobile_req_001',
    'aggregate_sequence': aggregateData, // List<double> of 288 values
  }),
);

final predictions = jsonDecode(response.body)['predictions'];
```

## 📝 License

MIT

## 🤝 Support

For issues or questions:
1. Check error messages in logs
2. Verify both services are running
3. Ensure scaler statistics match training data
4. Validate input data format and ranges

---

**Happy NILM Predicting!** 🔌⚡
