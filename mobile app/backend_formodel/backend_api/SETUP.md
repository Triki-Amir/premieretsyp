# NILM Backend API - Complete Setup Guide

A complete Express.js + Python Flask backend for serving NILM (Non-Intrusive Load Monitoring) model predictions via REST API.

## 📦 What's Included

```
backend_api/
├── src/
│   ├── server.js           # Express server (entry point)
│   ├── routes.js           # API routes & endpoints
│   ├── pythonClient.js     # Client for Python Flask service
│   ├── validation.js       # Request validation (Joi schema)
│   └── logger.js           # Centralized logging
├── python_service/
│   ├── model_service.py    # Flask API for model inference
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile          # Docker configuration (optional)
├── config/
│   └── config.js           # Centralized configuration
├── package.json            # Node.js dependencies
├── .env.example            # Environment template
├── test.js                 # API test suite
├── setup.sh / setup.bat    # Automated setup script
├── README.md               # Full documentation
├── API_EXAMPLES.md         # cURL & Python examples
└── DEPLOYMENT.md           # Production deployment guide
```

## 🚀 Quick Start (5 minutes)

### On Windows

```cmd
# 1. Open terminal in backend_api folder
cd c:\Users\chehin\Desktop\app_class\mobile-app\backend_formodel\backend_api

# 2. Run setup script
setup.bat

# 3. Create .env file
copy .env.example .env

# 4. Start Python service (Terminal 1)
cd python_service
venv\Scripts\activate.bat
python model_service.py

# 5. Start Express API (Terminal 2)
cd ..
npm start

# 6. Test the API (Terminal 3)
curl http://localhost:3000/api/health
```

### On macOS/Linux

```bash
# 1. Navigate to backend_api folder
cd backend_formodel/backend_api

# 2. Run setup script
bash setup.sh

# 3. Create .env file
cp .env.example .env

# 4. Start Python service (Terminal 1)
cd python_service
source venv/bin/activate
python model_service.py

# 5. Start Express API (Terminal 2)
cd ..
npm start

# 6. Test the API (Terminal 3)
curl http://localhost:3000/api/health
```

## 📋 Prerequisites

- **Node.js 16+**: [Download](https://nodejs.org/)
- **Python 3.9+**: [Download](https://www.python.org/)
- **CUDA Toolkit (optional)**: For GPU acceleration
- **4GB RAM minimum**: More if using GPU
- **Ports 3000 and 5000** available

## 🔧 Detailed Setup Instructions

### Step 1: Install Node.js Dependencies

```bash
cd backend_api
npm install
```

This installs:
- `express` - Web framework
- `cors` - Cross-origin resource sharing
- `axios` - HTTP client for Python service
- `joi` - Data validation
- `uuid` - Request ID generation
- `dotenv` - Environment variable management

### Step 2: Set Up Python Environment

```bash
cd python_service

# Create virtual environment
python -m venv venv

# Activate (choose based on your OS)
# Windows:
venv\Scripts\activate.bat
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

This installs:
- `torch` - PyTorch for model inference
- `numpy` - Array operations
- `flask` - Web framework
- `flask-cors` - CORS support
- `scikit-learn` - Preprocessing (StandardScaler)
- `pandas` - Data handling

### Step 3: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit .env with your settings
# Key configurations:
# - EXPRESS_PORT: Node.js API port (default: 3000)
# - FLASK_PORT: Python service port (default: 5000)
# - MODEL_NAME: Which model to use (TCN_best.pth, BiLSTM_best.pth, ATCN_best.pth)
# - MODEL_PATH: Path to saved models (default: ../NILM_SIDED/saved_models)
```

### Step 4: Verify Model Files

Ensure model files exist:

```bash
ls -la ../NILM_SIDED/saved_models/
# Should show:
# - TCN_best.pth
# - BiLSTM_best.pth (if trained)
# - ATCN_best.pth (if trained)
```

## 🎯 Usage

### Terminal 1: Start Python Flask Service

```bash
cd backend_api/python_service

# Activate environment
venv\Scripts\activate  # Windows
# or
source venv/bin/activate  # macOS/Linux

# Start service
python model_service.py
```

Expected output:
```
✅ Model loaded successfully
📍 Starting Flask server on port 5000
```

### Terminal 2: Start Express API Server

```bash
cd backend_api

# Install dependencies if not done
npm install

# Start server
npm start
```

Expected output:
```
✅ Express API listening on port 3000
📍 Access at http://localhost:3000
```

### Terminal 3: Test the API

```bash
# Health check
curl http://localhost:3000/api/health

# Service status
curl http://localhost:3000/api/status

# Make a prediction
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "aggregate_sequence": [150.5, 152.1, ..., 160.2]
  }'
```

See `API_EXAMPLES.md` for more examples.

## 📡 API Endpoints

### Health & Status

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/status` | Service status |
| GET | `/api/config` | Configuration (dev only) |

### Prediction

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/predict` | Run NILM prediction |

**Request Format:**
```json
{
  "request_id": "optional_string",
  "timestamp": "ISO8601_optional",
  "aggregate_sequence": [150.5, 152.1, ..., 160.2]  // Exactly 288 values
}
```

**Response Format:**
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

## ✅ Testing

### Automated Test Suite

```bash
# Install test dependencies
npm install --save-dev chalk

# Run tests
node test.js

# Or test specific endpoint
node test.js health
```

### Manual Testing with cURL

See `API_EXAMPLES.md` for comprehensive examples.

### Testing with Python

```python
import requests
import numpy as np

# Generate test data
data = np.random.rand(288).tolist()

response = requests.post(
    'http://localhost:3000/api/predict',
    json={'aggregate_sequence': data}
)

print(response.json()['predictions'])
```

## 🔍 Troubleshooting

### Issue: "Cannot connect to Flask service"

**Solution:**
```bash
# Ensure Flask service is running
# Terminal 1: python model_service.py

# Check if port 5000 is in use
lsof -i :5000  # macOS/Linux
netstat -ano | findstr :5000  # Windows

# Update FLASK_SERVICE_URL in .env
FLASK_SERVICE_URL=http://localhost:5000
```

### Issue: "Port 3000/5000 already in use"

**Solution:**
```bash
# Change ports in .env
EXPRESS_PORT=3001
FLASK_PORT=5001

# Or kill existing process
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

### Issue: "Model not found"

**Solution:**
```bash
# Verify model path
# Check if TCN_best.pth exists:
ls ../NILM_SIDED/saved_models/TCN_best.pth

# Update MODEL_PATH in .env
MODEL_PATH=../NILM_SIDED/saved_models
```

### Issue: "CUDA out of memory" or slow inference

**Solutions:**
1. Use CPU instead of GPU:
   ```python
   device = torch.device('cpu')
   ```

2. Reduce batch size (in model_service.py)

3. Check available GPU memory:
   ```bash
   nvidia-smi
   ```

## 📊 Architecture

```
Your Mobile App
    ↓ (HTTP POST)
Express API Server (Node.js)
    ├─ Validates request (schema, format, values)
    ├─ Calls Flask service
    └─ Returns formatted response
    ↓ (HTTP POST)
Flask Service (Python)
    ├─ Receives aggregate sequence
    ├─ Normalizes with StandardScaler
    ├─ Runs PyTorch model
    ├─ Inverse transforms predictions
    └─ Returns predictions JSON
    ↓
Express API Server
    └─ Returns to mobile app
```

## 🔐 Security

### CORS Configuration

Edit `.env`:
```env
# Allow specific domain
CORS_ORIGIN=https://your-frontend-domain.com

# Or allow all (development only)
CORS_ORIGIN=*
```

### API Key Authentication (Optional)

See `DEPLOYMENT.md` for adding API key protection.

### HTTPS in Production

See `DEPLOYMENT.md` for SSL/TLS setup.

## 📈 Performance Tips

1. **Use GPU** if available for faster inference
2. **Cache predictions** if same sequences are requested repeatedly
3. **Run multiple Flask instances** behind a load balancer for scaling
4. **Monitor resource usage** (CPU, memory, GPU)
5. **Set appropriate timeouts** in production

## 📚 Documentation

- **README.md** - Full API documentation
- **API_EXAMPLES.md** - cURL, Python, JavaScript examples
- **DEPLOYMENT.md** - Production setup (Docker, AWS, Heroku)
- **API_CONTRACT.md** (NILM_SIDED) - Model specifications

## 🛠️ Model Configuration

The API is pre-configured for `TCN_best.pth`. To use different models:

```bash
# Edit .env
MODEL_NAME=BiLSTM_best.pth
# or
MODEL_NAME=ATCN_best.pth
```

Then update `python_service/model_service.py` to load the correct architecture:

```python
if MODEL_NAME == 'TCN_best.pth':
    model = TCNModel(...)
elif MODEL_NAME == 'BiLSTM_best.pth':
    model = BiLSTMModel(...)
elif MODEL_NAME == 'ATCN_best.pth':
    model = ATCNModel(...)
```

## 🔄 Development Workflow

1. **Make code changes** to `src/` or `python_service/`
2. **Restart services** (Ctrl+C and npm start / python model_service.py)
3. **Test changes** with curl or test suite
4. **Check logs** for errors

Enable auto-restart with:
```bash
npm install -D nodemon
npm run dev
```

## 📞 Support & Issues

1. **Check logs** - Both services log errors
2. **Test endpoints** - Use curl to test directly
3. **Verify configuration** - Check .env and config.js
4. **Check connectivity** - Ensure both services can reach each other
5. **Review examples** - See API_EXAMPLES.md for working requests

## 🎉 Next Steps

1. ✅ Verify API is working (test endpoints)
2. 📱 Integrate with mobile app (replace `http://localhost:3000` with actual server)
3. 🚀 Deploy to production (see DEPLOYMENT.md)
4. 📊 Monitor performance and logs
5. 🔄 Optimize based on usage patterns

## 📝 Quick Reference

```bash
# Start everything
terminal1> cd python_service && python model_service.py
terminal2> npm start

# Test
curl http://localhost:3000/api/health

# View logs
terminal1-2: Console output (watch for errors)

# Stop
Ctrl+C in each terminal

# Change port
# Edit .env:
EXPRESS_PORT=3001
FLASK_PORT=5001
```

---

**You're all set!** 🎉 The NILM backend API is ready to serve predictions to your mobile app.

For detailed API usage, see `README.md`.
For production deployment, see `DEPLOYMENT.md`.
For request examples, see `API_EXAMPLES.md`.
