# Example API Requests

## 1. Health Check

```bash
curl -X GET http://localhost:3000/api/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-23T14:30:00Z",
  "version": "1.0.0"
}
```

## 2. Service Status

```bash
curl -X GET http://localhost:3000/api/status
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

## 3. NILM Prediction with 288-value sequence

```bash
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "test_001",
    "timestamp": "2025-11-23T14:30:00Z",
    "aggregate_sequence": [
      150.5, 152.1, 148.9, 155.0, 160.2, 158.7, 162.3, 165.1, 168.5, 171.2,
      174.8, 177.5, 180.2, 182.9, 185.6, 188.3, 191.0, 193.7, 196.4, 199.1,
      201.8, 204.5, 207.2, 209.9, 212.6, 215.3, 218.0, 220.7, 223.4, 226.1,
      228.8, 231.5, 234.2, 236.9, 239.6, 242.3, 245.0, 247.7, 250.4, 253.1,
      255.8, 258.5, 261.2, 263.9, 266.6, 269.3, 272.0, 274.7, 277.4, 280.1,
      282.8, 285.5, 288.2, 290.9, 293.6, 296.3, 299.0, 301.7, 304.4, 307.1,
      309.8, 312.5, 315.2, 317.9, 320.6, 323.3, 326.0, 328.7, 331.4, 334.1,
      336.8, 339.5, 342.2, 344.9, 347.6, 350.3, 353.0, 355.7, 358.4, 361.1,
      363.8, 366.5, 369.2, 371.9, 374.6, 377.3, 380.0, 382.7, 385.4, 388.1,
      390.8, 393.5, 396.2, 398.9, 401.6, 404.3, 407.0, 409.7, 412.4, 415.1,
      417.8, 420.5, 423.2, 425.9, 428.6, 431.3, 434.0, 436.7, 439.4, 442.1,
      444.8, 447.5, 450.2, 452.9, 455.6, 458.3, 461.0, 463.7, 466.4, 469.1,
      471.8, 474.5, 477.2, 479.9, 482.6, 485.3, 488.0, 490.7, 493.4, 496.1,
      498.8, 501.5, 504.2, 506.9, 509.6, 512.3, 515.0, 517.7, 520.4, 523.1,
      525.8, 528.5, 531.2, 533.9, 536.6, 539.3, 542.0, 544.7, 547.4, 550.1,
      552.8, 555.5, 558.2, 560.9, 563.6, 566.3, 569.0, 571.7, 574.4, 577.1,
      579.8, 582.5, 585.2, 587.9, 590.6, 593.3, 596.0, 598.7, 601.4, 604.1,
      606.8, 609.5, 612.2, 614.9, 617.6, 620.3, 623.0, 625.7, 628.4, 631.1,
      633.8, 636.5, 639.2, 641.9, 644.6, 647.3, 650.0, 652.7, 655.4, 658.1,
      660.8, 663.5, 666.2, 668.9, 671.6, 674.3, 677.0, 679.7, 682.4, 685.1,
      687.8, 690.5, 693.2, 695.9, 698.6, 701.3, 704.0, 706.7, 709.4, 712.1,
      714.8, 717.5, 720.2, 722.9, 725.6, 728.3, 731.0, 733.7, 736.4, 739.1,
      741.8, 744.5, 747.2, 749.9, 752.6, 755.3, 758.0, 760.7, 763.4, 766.1,
      768.8, 771.5, 774.2, 776.9, 779.6, 782.3, 785.0, 787.7, 790.4, 793.1,
      795.8, 798.5, 801.2, 803.9, 806.6, 809.3, 812.0, 814.7, 817.4, 820.1,
      822.8, 825.5, 828.2, 830.9, 833.6, 836.3, 839.0, 841.7, 844.4, 847.1
    ]
  }'
```

Response:
```json
{
  "request_id": "test_001",
  "timestamp": "2025-11-23T14:32:15Z",
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

## 4. Error Example - Missing aggregate_sequence

```bash
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"request_id": "test_002"}'
```

Response:
```json
{
  "request_id": "test_002",
  "status": "error",
  "error": "Validation failed: \"aggregate_sequence\" is required",
  "timestamp": "2025-11-23T14:32:20Z"
}
```

## 5. Error Example - Invalid sequence length

```bash
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "test_003",
    "aggregate_sequence": [150.5, 152.1, 148.9]
  }'
```

Response:
```json
{
  "request_id": "test_003",
  "status": "error",
  "error": "Validation failed: \"aggregate_sequence\" must contain 288 items",
  "timestamp": "2025-11-23T14:32:25Z"
}
```

## 6. Using Python to generate test data and request

```python
import requests
import numpy as np
import json

# Generate realistic aggregate power sequence (24h at 5min intervals)
# Simulate a typical daily load curve
hours = np.linspace(0, 24, 288)
base_load = 200  # Base load in kW
time_of_day_curve = 150 * np.sin(np.pi * (hours - 6) / 12) ** 2  # Peak at noon
daily_load = base_load + time_of_day_curve + np.random.normal(0, 10, 288)

# Ensure non-negative and reasonable bounds
daily_load = np.clip(daily_load, 100, 800)

# Prepare request
payload = {
    'request_id': 'python_test_001',
    'timestamp': '2025-11-23T14:30:00Z',
    'aggregate_sequence': daily_load.tolist()
}

# Send request
response = requests.post(
    'http://localhost:3000/api/predict',
    json=payload
)

# Parse response
result = response.json()

if result['status'] == 'success':
    print("✅ Prediction successful!")
    print(f"Request ID: {result['request_id']}")
    print(f"Processing time: {result['processingTimeMs']}ms")
    print("\nPredictions:")
    for appliance, power in result['predictions'].items():
        print(f"  {appliance}: {power:.2f} kW")
else:
    print(f"❌ Error: {result['error']}")
```

## 7. Using cURL with random data (bash)

```bash
#!/bin/bash

# Generate 288 random values between 100 and 800
values=""
for i in {1..288}; do
    val=$(awk "BEGIN {printf \"%.1f\", 100 + rand() * 700}")
    if [ $i -eq 1 ]; then
        values="$val"
    else
        values="$values, $val"
    fi
done

# Create JSON payload
payload=$(cat <<EOF
{
  "request_id": "bash_test_001",
  "aggregate_sequence": [$values]
}
EOF
)

# Send request
curl -X POST http://localhost:3000/api/predict \
  -H "Content-Type: application/json" \
  -d "$payload"
```

## Testing Tips

1. **Validate input before sending**:
   - Ensure sequence has exactly 288 values
   - Ensure all values are numeric and not NaN/Inf
   - Ensure values are in reasonable range (e.g., 0-1000 kW)

2. **Check request/response IDs**:
   - The same request_id should appear in response
   - Helps track requests in logs

3. **Monitor timing**:
   - `processingTimeMs` includes preprocessing + inference + postprocessing
   - Typical times: 50-300ms depending on hardware

4. **Inspect predictions**:
   - EVSE, CS, BA should be >= 0 (loads)
   - PV, CHP should be <= 0 (generation)
   - Sum of all predictions should be close to aggregate input

---

For more examples, see the main README.md
