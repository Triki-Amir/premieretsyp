# NILM Backend API - Quick Reference Card

## 🚀 30-Second Start

```bash
# Windows
cd backend_api
setup.bat

# macOS/Linux
cd backend_api
bash setup.sh
```

Then open 2 terminals:
```
Terminal 1: cd python_service && venv\Scripts\activate && python model_service.py
Terminal 2: npm start
Terminal 3: curl http://localhost:3000/api/health
```

## 📍 Key Ports & URLs

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Express API | 3000 | http://localhost:3000 | Main API |
| Flask Service | 5000 | http://localhost:5000 | Model inference |
| Node Dev | 5173 | - | (for nodemon auto-reload) |

## 🔗 API Endpoints Cheat Sheet

```bash
# Health
curl http://localhost:3000/api/health

# Status
curl http://localhost:3000/api/status

# Predict (replace 288 values)
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"aggregate_sequence": [150, 151, 152, ...]}'
```

## 📝 Input Format

```json
{
  "request_id": "optional_id",
  "aggregate_sequence": [value1, value2, ..., value288],
  "timestamp": "optional_ISO8601"
}
```

**Requirements:**
- `aggregate_sequence` must have **exactly 288** numbers
- All values must be finite (no NaN/Infinity)
- Represents 24 hours at 5-minute intervals

## 📤 Output Format

```json
{
  "request_id": "req_id",
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

## 🔤 Appliance Codes

| Code | Full Name | Type | Values |
|------|-----------|------|--------|
| EVSE | EV Charger | Load | ≥ 0 |
| PV | Solar Panel | Generation | ≤ 0 |
| CS | Cooling System | Load | ≥ 0 |
| CHP | Heat & Power | Generation | ≤ 0 |
| BA | Battery/Automation | Load | ≥ 0 |

## ⚙️ Configuration Quick Edit

**.env file key settings:**

```env
EXPRESS_PORT=3000              # API port
FLASK_PORT=5000                # Python service port
MODEL_NAME=TCN_best.pth         # TCN, BiLSTM_best.pth, ATCN_best.pth
LOG_LEVEL=info                  # debug, info, warn, error
CORS_ORIGIN=*                   # *, your-domain.com, etc.
```

## 🔧 Common Commands

```bash
# Start Express (Terminal 2)
npm start

# Start with auto-reload (requires nodemon)
npm run dev

# Start Flask (Terminal 1)
cd python_service
python model_service.py

# Activate Python venv (Terminal 1)
# Windows
venv\Scripts\activate.bat
# macOS/Linux
source venv/bin/activate

# Run tests
npm install --save-dev chalk
node test.js

# Check service health
curl http://localhost:3000/api/health
curl http://localhost:5000/health

# Kill process on port
# Windows
netstat -ano | findstr :3000 | findstr LISTENING | awk '{print $5}' | xargs taskkill /PID /F
# macOS/Linux
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

## 🐛 Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Port 3000/5000 in use | Change in `.env` |
| Flask won't start | Check venv activated, model exists |
| Validation error | Check array length = 288 |
| Slow response | Enable GPU: `nvidia-smi` |
| Connection refused | Both services running? Check ports |
| NaN in predictions | Check input values are valid |

## 📚 Documentation Map

```
Need to:                          Read:
├─ Get started                    SETUP.md
├─ Use the API                    README.md
├─ See code examples              API_EXAMPLES.md
├─ Deploy to production           DEPLOYMENT.md
├─ Understand architecture        VISUAL_OVERVIEW.md
├─ Get project overview           PROJECT_SUMMARY.md
└─ Quick reference                This file! 📍
```

## 🎯 Model Selection Guide

```
Quick decisions:

Need spike detection?     → TCN_best.pth
Want smooth output?       → BiLSTM_best.pth
Complex patterns?         → ATCN_best.pth

Switch model:
1. Edit .env: MODEL_NAME=BiLSTM_best.pth
2. Restart services
3. Done!
```

## 🚨 Error Codes Reference

| Code | Meaning | Solution |
|------|---------|----------|
| 200 | Success | All good |
| 400 | Bad request | Check JSON format, array length |
| 401 | Unauthorized | Check API key (if enabled) |
| 403 | Forbidden | Config endpoint only in dev |
| 404 | Not found | Wrong endpoint URL |
| 500 | Server error | Check service logs |
| 503 | Service unavailable | Flask service down |

## 📊 Expected Performance

| Metric | Typical Value |
|--------|---|
| Inference time | 50-300ms |
| Response time | 100-350ms |
| Memory (Python) | ~500MB |
| Memory (Node) | ~300MB |
| GPU memory | ~800MB |
| Max concurrent | 10-50 |

## 🔐 Security Checklist

- [ ] Change `CORS_ORIGIN` from `*` to your domain
- [ ] Don't expose `.env` file
- [ ] Use HTTPS in production
- [ ] Add API key authentication (optional)
- [ ] Set rate limiting (optional)
- [ ] Monitor logs for errors
- [ ] Keep dependencies updated

## 🌐 Integration Examples

### cURL
```bash
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"aggregate_sequence": [...]}'
```

### Python
```python
import requests
resp = requests.post('http://localhost:3000/api/predict',
                     json={'aggregate_sequence': [...]})
print(resp.json()['predictions'])
```

### JavaScript/Node
```javascript
const resp = await fetch('http://localhost:3000/api/predict', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({aggregate_sequence: [...]})
});
const result = await resp.json();
console.log(result.predictions);
```

### Dart/Flutter
```dart
final resp = await http.post(
  Uri.parse('http://localhost:3000/api/predict'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'aggregate_sequence': aggregateData})
);
final predictions = jsonDecode(resp.body)['predictions'];
```

## 📱 Mobile App Integration

Replace `http://localhost:3000` with your server address:

```dart
const String API_URL = 'http://YOUR_SERVER:3000';

final response = await http.post(
  Uri.parse('$API_URL/api/predict'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'aggregate_sequence': aggregateSequence  // List<double> [288 values]
  })
);

if (response.statusCode == 200) {
  final predictions = jsonDecode(response.body)['predictions'];
  // Display: EVSE, PV, CS, CHP, BA
} else {
  // Handle error
}
```

## 🗂️ File Locations

```
c:\Users\chehin\Desktop\app_class\mobile-app\
├── flutter_application_1\        ← Your mobile app
├── backend\                       ← Existing backend (leave as-is)
└── backend_formodel\
    ├── NILM_SIDED\
    │   ├── workspace.ipynb        ← Training notebook
    │   ├── saved_models\          ← Model files here
    │   │   ├── TCN_best.pth
    │   │   ├── BiLSTM_best.pth
    │   │   └── ATCN_best.pth
    │   └── API_CONTRACT.md
    └── backend_api\               ← YOUR NEW API SERVER 📍
        ├── src\
        ├── python_service\
        ├── config\
        ├── package.json
        ├── .env
        └── README.md (and other docs)
```

## ⏱️ Setup Time Estimate

| Step | Time |
|------|------|
| Clone/copy files | < 1 min |
| Install Node packages | 2-3 min |
| Setup Python venv | 2-3 min |
| Copy `.env.example` to `.env` | < 1 min |
| Start services | < 1 min |
| Test endpoints | 1-2 min |
| **Total** | **~10 minutes** |

## ✅ Pre-flight Checklist

Before starting:
- [ ] Node.js installed? `node --version`
- [ ] Python 3.9+? `python --version`
- [ ] Models exist? Check `../NILM_SIDED/saved_models/`
- [ ] Ports 3000, 5000 free? `netstat -ano`
- [ ] `.env` file created?
- [ ] Dependencies installed? `npm install` and `pip install -r requirements.txt`

## 🎊 You're Ready!

Once setup is done:

1. ✅ Backend API running on port 3000
2. ✅ Python service running on port 5000
3. ✅ Ready to accept `/api/predict` requests
4. ✅ Ready to integrate with mobile app

**Next step**: Read README.md for detailed API documentation or integrate with your mobile app!

---

**Bookmark this for quick reference!** 🔖
