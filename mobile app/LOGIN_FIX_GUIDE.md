# Login Issue Fix - Quick Guide

## Issue
Login always fails with "Invalid email or password" even with correct credentials.

## Root Cause
The password validation is working, but there might be an issue with how passwords are stored or compared.

## Solution: Test with Fresh Registration

### Step 1: Ensure Backend is Running
```bash
cd "c:\premieretsyp\energy-trading-network\application"
node app.js
```

**You should see:**
```
🚀 Energy Trading API server running on http://localhost:3000
✓ Successfully connected to gateway using admin identity
```

### Step 2: Register a Test Factory
Use these exact credentials:

**Email:** `demo@test.com`  
**Password:** `Password123`

**Via Flutter App:**
1. Open the app
2. Click "Sign Up" tab
3. Fill in:
   - Factory Name: `Demo Factory`
   - Email: `demo@test.com`
   - Password: `Password123`
   - Fiscal Matricule: `FM-DEMO-001`
   - Location: `Test Zone`
   - Energy Capacity: `3000`
   - Contact: `+216-555-1234`
   - Energy Source: `solar`
4. Click "Sign Up"

**Via Command Line (Alternative):**
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "factory_name": "Demo Factory",
    "email": "demo@test.com",
    "password": "Password123",
    "fiscal_matricule": "FM-DEMO-001",
    "localisation": "Test Zone",
    "energy_capacity": 3000,
    "contact_info": "+216-555-1234",
    "energy_source": "solar"
  }'
```

### Step 3: Test Login
**Via Flutter App:**
1. Switch to "Login" tab
2. Email: `demo@test.com`
3. Password: `Password123`
4. Click "Login"

**Via Command Line (to verify):**
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Password123"}'
```

**Expected Response:**
```json
{
  "message": "Login successful!",
  "factory": {
    "id": "Factory_...",
    "factory_name": "Demo Factory",
    "email": "demo@test.com",
    ...
  }
}
```

## Password Requirements

The backend enforces these rules:
- ✅ Minimum 8 characters
- ✅ At least one letter (a-z, A-Z)
- ✅ At least one number (0-9)

### Valid Passwords:
- ✅ `Password123`
- ✅ `Test1234`
- ✅ `Solar2024`
- ✅ `Energy99`

### Invalid Passwords:
- ❌ `password` (no number)
- ❌ `12345678` (no letter)
- ❌ `Pass1` (too short)

## Debugging Steps

### 1. Check Backend Console
When you attempt login, you should see in the backend console:
```
Received login request with email: demo@test.com
Login successful for: demo@test.com
```

If you see:
```
Login failed: Invalid password.
```
The password is incorrect.

If you see:
```
Login failed: Email not found.
```
The email doesn't exist in the blockchain.

### 2. Check Network Connection
```bash
curl http://localhost:3000/test
```
Should return: `{"message":"Backend server is running!"}`

### 3. Test Registration First
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "factory_name": "Quick Test",
    "email": "quick@test.com",
    "password": "Quick123",
    "fiscal_matricule": "FM-QUICK-999"
  }'
```

Then immediately login:
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"quick@test.com","password":"Quick123"}'
```

## Common Issues

### Issue: "Required fields are missing"
**Solution:** Make sure all required fields are filled:
- factory_name
- email  
- password
- fiscal_matricule

### Issue: "Email or Fiscal Matricule already exists"
**Solution:** Use a different email or fiscal matricule. Each must be unique.

### Issue: "Password must be at least 8 characters long"
**Solution:** Use a longer password (minimum 8 characters).

### Issue: "Password must contain at least one letter and one number"
**Solution:** Include both letters AND numbers in your password.

## Flutter App Configuration

Make sure the app is configured to connect to the correct backend:

**File:** `lib/config/api_config.dart`

For web/desktop:
```dart
static const String _host = 'localhost';
```

For Android emulator:
```dart
static const String _host = '10.0.2.2';
```

For physical device:
```dart
static const String _host = '192.168.1.XXX'; // Your computer's IP
```

## Working Test Account

If all else fails, use this pre-registered account that should work:

**Email:** `test@solar.com`  
**Password:** `Test1234`  
**Factory ID:** `Factory_1764378004793_09xw867`

(This was just registered and should be in the blockchain)

## Verification Commands

### 1. Check if backend is responding:
```bash
curl http://localhost:3000/test
```

### 2. Register a factory:
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{"factory_name":"Test","email":"verify@test.com","password":"Verify123","fiscal_matricule":"FM-VER-001"}'
```

### 3. Login immediately after:
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"verify@test.com","password":"Verify123"}'
```

All three commands should succeed!
