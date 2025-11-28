# NILM Backend API - Visual Overview

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR MOBILE APP (Flutter)                  │
│                                                                 │
│  Shows energy predictions from disaggregation                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP POST /api/predict
                         │ (288 aggregate power values)
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│         EXPRESS.JS API SERVER (Node.js on Port 3000)            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Endpoints:                                              │   │
│  │  • GET  /api/health       → Health check              │   │
│  │  • GET  /api/status       → Service status             │   │
│  │  • POST /api/predict      → Model prediction           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Middleware:                                             │   │
│  │  • JSON parsing                                         │   │
│  │  • CORS handling                                        │   │
│  │  • Request validation (Joi schema)                      │   │
│  │  • Error handling                                       │   │
│  │  • Logging                                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Python Service Client:                                  │   │
│  │  • HTTP client (axios)                                  │   │
│  │  • Health checks                                        │   │
│  │  • Error handling                                       │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           │ HTTP POST /predict
                           │ (Pass through to model)
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│         FLASK SERVICE (Python on Port 5000)                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Model Loading (On Startup):                             │   │
│  │  • Load PyTorch model from disk                          │   │
│  │  • Initialize CUDA/CPU device                           │   │
│  │  • Prepare model for inference                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Preprocessing:                                          │   │
│  │  1. Receive aggregate sequence (288 floats)            │   │
│  │  2. Validate (no NaN/Inf, correct length)              │   │
│  │  3. Apply StandardScaler normalization                 │   │
│  │  4. Convert to PyTorch tensor (1, 288, 1)              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Model Inference:                                        │   │
│  │  • Forward pass through TCN/BiLSTM/ATCN               │   │
│  │  • Clamp outputs to prevent overflow                  │   │
│  │  • Output shape: (1, 5) [5 appliances]                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Postprocessing:                                         │   │
│  │  1. Inverse transform (StandardScaler)                 │   │
│  │  2. Apply sign conventions:                            │   │
│  │     • Loads (EVSE, CS, BA) ≥ 0                        │   │
│  │     • Generation (PV, CHP) ≤ 0                        │   │
│  │  3. Return 5 appliance predictions                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Models Available:                                       │   │
│  │  🔹 TCN       (Temporal Convolutional Network)          │   │
│  │  🔹 BiLSTM    (Bidirectional LSTM)                      │   │
│  │  🔹 ATCN      (Attention TCN)                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           │ JSON Response
                           │ {predictions: {...}}
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│         EXPRESS.JS API SERVER (Return Response)                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Response Formatting:                                    │   │
│  │  • Add request_id (for tracking)                        │   │
│  │  • Add timestamp                                        │   │
│  │  • Add processing time                                  │   │
│  │  • Set status: "success" or "error"                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           │ HTTP 200 (or error code)
                           │ {
                           │   predictions: {
                           │     EVSE: 45.2,
                           │     PV: -12.5,
                           │     CS: 22.1,
                           │     CHP: 0.0,
                           │     BA: 5.3
                           │   },
                           │   status: "success",
                           │   processingTimeMs: 125
                           │ }
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR MOBILE APP                            │
│                                                                 │
│  Displays:                                                      │
│  • EVSE: 45.2 kW (EV Charger)                                 │
│  • PV: -12.5 kW (Solar Generation)                            │
│  • CS: 22.1 kW (Cooling System)                               │
│  • CHP: 0.0 kW (Heat & Power)                                 │
│  • BA: 5.3 kW (Battery/Automation)                            │
└─────────────────────────────────────────────────────────────────┘
```

## 📂 File Structure

```
backend_api/
│
├── 🚀 Entry Points
│   ├── src/server.js              ← Start Express here
│   └── python_service/            ← Start Flask here
│       └── model_service.py
│
├── 🔌 API Layer (src/)
│   ├── routes.js                  (All endpoints defined here)
│   ├── pythonClient.js            (Calls Python service)
│   ├── validation.js              (Input validation rules)
│   ├── logger.js                  (Logging utility)
│   └── server.js                  (Express setup & start)
│
├── 🧠 Model Layer (python_service/)
│   ├── model_service.py           (Flask server + model inference)
│   └── requirements.txt            (Python dependencies)
│
├── ⚙️ Configuration
│   ├── config/config.js           (Centralized settings)
│   ├── .env.example               (Environment template)
│   └── .env                       (Your configuration - copy from .env.example)
│
├── 📦 Dependencies
│   ├── package.json               (Node packages)
│   └── python_service/requirements.txt (Python packages)
│
├── 📚 Documentation
│   ├── SETUP.md                   ← START HERE
│   ├── README.md                  (Full API docs)
│   ├── API_EXAMPLES.md            (cURL, Python examples)
│   ├── DEPLOYMENT.md              (Production setup)
│   └── PROJECT_SUMMARY.md         (Overview)
│
└── 🧪 Testing
    └── test.js                    (Automated tests)
```

## 🔄 Request/Response Flow

### 1. Client Sends Prediction Request

```
POST /api/predict HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "request_id": "req_001",
  "aggregate_sequence": [150.5, 152.1, 148.9, ..., 160.2]
  ↑                      └─── Exactly 288 values
  └─ Optional for tracking
}
```

### 2. Express Validates & Routes

```
Express → Validation
  ✓ Check if aggregate_sequence exists
  ✓ Check if it has exactly 288 elements
  ✓ Check all values are numbers (not NaN/Inf)
  ✓ Proceed to Python service
  or
  ✗ Return 400 error if validation fails
```

### 3. Flask Runs Inference

```
Flask Preprocessing
  Input: [150.5, 152.1, 148.9, ...]

  ↓ StandardScaler.fit_transform()
  Normalized: [-0.5, -0.3, -0.8, ...]

  ↓ torch.FloatTensor()
  Tensor: (1, 288, 1)

  ↓ Model.forward()
  TCN/BiLSTM/ATCN inference

  ↓ Clamp to [-8, 8]
  Safe values: [0.2, -0.1, 0.5, -0.2, 0.1]

  ↓ StandardScaler.inverse_transform()
  Real units: [45.2, -12.5, 22.1, 0.0, 5.3]

  ↓ Apply sign conventions
  Final: {EVSE: 45.2, PV: -12.5, CS: 22.1, CHP: 0.0, BA: 5.3}
```

### 4. Response Returned

```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "request_id": "req_001",
  "predictions": {
    "EVSE": 45.2,
    "PV": -12.5,
    "CS": 22.1,
    "CHP": 0.0,
    "BA": 5.3
  },
  "status": "success",
  "processingTimeMs": 145,
  "timestamp": "2025-11-23T14:30:00Z"
}
```

## 🎯 Configuration Overview

```
.env File Contents:

[Express Server]
NODE_ENV=development
EXPRESS_PORT=3000
CORS_ORIGIN=*

[Python Service]
FLASK_PORT=5000
FLASK_SERVICE_URL=http://localhost:5000

[Model]
MODEL_NAME=TCN_best.pth          ← Change this to switch models
MODEL_PATH=../NILM_SIDED/saved_models

[Logging]
LOG_LEVEL=info                   ← Change to 'debug' for more logs
```

## 📊 Data Flow Visualization

```
24 Hours of Power Data
        │
        │ 5-minute intervals
        │ (288 readings)
        ▼
[150.5, 152.1, 148.9, ..., 160.2]
        │
        │ POST /api/predict
        ▼
Express Validates
        │
        │ HTTP Call
        ▼
Flask Service
        │
    ├─→ Normalize (StandardScaler)
    ├─→ Convert to Tensor
    ├─→ Run Model (TCN/BiLSTM/ATCN)
    ├─→ Inverse Transform
    └─→ Apply Sign Convention
        │
        ▼
{
  "EVSE": 45.2,    ← EV Charger Load
  "PV": -12.5,     ← Solar Generation (negative)
  "CS": 22.1,      ← Cooling Load
  "CHP": 0.0,      ← Combined Heat & Power
  "BA": 5.3        ← Battery/Automation Load
}
        │
        │ JSON Response
        ▼
Mobile App Display
        │
        ▼
User sees disaggregated power breakdown
```

## 🚀 Quick Start Sequence

```
1. cd backend_api

2. Run setup.bat (Windows) or bash setup.sh (macOS/Linux)

3. Copy .env.example to .env

4. Terminal 1: cd python_service && venv\Scripts\activate && python model_service.py
   ⏳ Wait for: "✅ Model loaded successfully"

5. Terminal 2: npm start
   ⏳ Wait for: "✅ Express API listening on port 3000"

6. Terminal 3: curl http://localhost:3000/api/health
   ✅ Should return {"status": "healthy", ...}

7. Open README.md for API usage examples
```

## 🔍 Debugging Checklist

```
❓ API not responding?
  └─ Check if npm start ran successfully

❓ Flask service error?
  └─ Check if venv activated
  └─ Check if model file exists

❓ Validation error?
  └─ Check aggregate_sequence has exactly 288 values
  └─ Check all values are numbers

❓ Slow inference?
  └─ Check if GPU is being used: nvidia-smi
  └─ Check CPU usage: top / htop

❓ Port already in use?
  └─ Change EXPRESS_PORT and FLASK_PORT in .env
```

## ✨ Features at a Glance

| Feature | Status | Location |
|---------|--------|----------|
| Health Check API | ✅ | `src/routes.js` |
| NILM Prediction | ✅ | `src/routes.js` |
| Input Validation | ✅ | `src/validation.js` |
| Error Handling | ✅ | `src/routes.js` + `python_service/` |
| Logging | ✅ | `src/logger.js` |
| CORS Support | ✅ | `src/server.js` |
| Configuration | ✅ | `config/config.js` + `.env` |
| Model Loading | ✅ | `python_service/model_service.py` |
| GPU Support | ✅ | `python_service/model_service.py` |
| Multiple Models | ✅ | TCN, BiLSTM, ATCN |
| Documentation | ✅ | SETUP.md, README.md, etc. |
| Test Suite | ✅ | `test.js` |
| Docker Support | ✅ | Dockerfile templates in docs |

## 📱 Integration Checklist

- [ ] Backend is running on port 3000
- [ ] Python service is running on port 5000
- [ ] Test `/api/health` endpoint
- [ ] Test `/api/predict` with sample data
- [ ] Replace `http://localhost:3000` in mobile app with production URL
- [ ] Configure CORS for your domain
- [ ] Set up logging/monitoring
- [ ] Test with real data from your app
- [ ] Deploy to production (see DEPLOYMENT.md)

---

## 📖 Documentation Map

```
Starting Out?
  └─ Read SETUP.md first

Need API Details?
  └─ Read README.md

Want Code Examples?
  └─ See API_EXAMPLES.md

Going to Production?
  └─ Follow DEPLOYMENT.md

Need Project Overview?
  └─ Read PROJECT_SUMMARY.md

Want Visual Guide?
  └─ You're reading it! 📍
```

---

**Status**: ✅ Ready to Deploy

**Next Step**: Follow the "Quick Start Sequence" above or read SETUP.md
