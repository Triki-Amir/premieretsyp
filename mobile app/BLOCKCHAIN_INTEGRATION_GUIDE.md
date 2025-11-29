# Mobile App - Blockchain Backend Integration Guide

## Overview
This guide will help you connect your Flutter mobile app to the Hyperledger Fabric blockchain backend.

## Architecture
```
Flutter Mobile App (Port: Dynamic)
    ↓
Node.js Backend API (Port: 3000)
    ↓
Hyperledger Fabric Blockchain Network
    ↓
CouchDB (Data persistence)
```

## Prerequisites

### 1. Backend Running
Ensure the blockchain backend is running:
```bash
cd "c:\premieretsyp\energy-trading-network\application"
node app.js
```

You should see:
```
🚀 Energy Trading API server running on http://localhost:3000
✓ Successfully connected to gateway using admin identity
```

### 2. Network Running
Verify Hyperledger Fabric network is up:
```bash
docker ps
```

You should see containers for:
- `peer0.org1.example.com`
- `peer0.org2.example.com`
- `orderer.example.com`
- Chaincode containers

## Configuration

### For Different Environments

#### 1. **Web Development (Chrome/Edge)**
No changes needed! Uses `localhost:3000` by default.

#### 2. **Android Emulator**
Update `lib/config/api_config.dart`:
```dart
static const String _host = '10.0.2.2'; // Special alias for host machine
```

#### 3. **iOS Simulator**
No changes needed! Uses `localhost:3000` by default.

#### 4. **Physical Device (Android/iOS)**
Find your computer's IP address:

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# Look for "inet" under your active network interface
# Example: 192.168.1.100
```

Then update `lib/config/api_config.dart`:
```dart
static const String _host = '192.168.1.100'; // Your actual IP
```

**Important:** Make sure your phone and computer are on the same Wi-Fi network!

## Testing the Connection

### 1. Start the Backend
```bash
cd "c:\premieretsyp\energy-trading-network\application"
node app.js
```

### 2. Test Backend Endpoint
```bash
# Test from command line
curl http://localhost:3000/test

# Should return:
# {"message":"Backend server is running!"}
```

### 3. Run Flutter App
```bash
cd "c:\premieretsyp\mobile app\flutter_application_1"
flutter run -d chrome  # For web
# OR
flutter run -d windows # For Windows desktop
# OR
flutter run            # For connected device/emulator
```

### 4. Test in App
The app should:
- ✅ Show "Backend Connected" on login screen
- ✅ Allow factory registration
- ✅ Display factory list
- ✅ Create and execute trades

## Available API Endpoints

### Authentication
- `POST /login` - Factory login
- `POST /signup` - Register new factory
- `GET /test` - Test connection

### Factories
- `GET /api/factories` - Get all factories
- `GET /api/factory/:id` - Get factory details
- `PUT /api/factory/:id/energy` - Update energy data
- `GET /api/factory/:id/balance` - Get balances
- `GET /api/factory/:id/energy-status` - Get energy status

### Trades
- `POST /api/trade/create` - Create new trade
- `POST /api/trade/execute` - Execute trade
- `GET /api/trade/:id` - Get trade details
- `GET /api/trades` - Get all trades

### Energy Operations
- `POST /api/energy/mint` - Mint energy tokens
- `POST /api/energy/transfer` - Transfer energy

### Offers
- `GET /api/offers` - Get all offers
- `POST /api/offers` - Create offer
- `PUT /api/offers/:id` - Update offer status

## Example API Calls from Flutter

### Register Factory
```dart
final apiService = BackendApiService();
try {
  final result = await apiService.signup(
    factoryName: "Green Energy Corp",
    email: "factory@example.com",
    password: "password123",
    fiscalMatricule: "FM-2024-001",
    localisation: "Tunis Industrial Zone",
    energyCapacity: 5000,
    contactInfo: "+216-123-456",
    energySource: "solar",
  );
  print('Factory registered: ${result['factoryId']}');
} catch (e) {
  print('Error: $e');
}
```

### Create Trade
```dart
final blockchainService = BlockchainApiService();
try {
  final result = await blockchainService.createTrade(
    tradeId: 'TRADE_${DateTime.now().millisecondsSinceEpoch}',
    sellerId: 'Factory_123_abc',
    buyerId: 'Factory_456_def',
    amount: 200.0,
    pricePerUnit: 0.15,
  );
  print('Trade created: ${result['data']}');
} catch (e) {
  print('Error: $e');
}
```

## Troubleshooting

### Issue 1: "Cannot connect to backend server"
**Solution:**
1. Check if backend is running: `curl http://localhost:3000/test`
2. Verify port 3000 is not blocked by firewall
3. For Android emulator, use `10.0.2.2` instead of `localhost`
4. For physical device, use your computer's IP address

### Issue 2: "SyntaxError: Unexpected token '<'"
**Cause:** App is receiving HTML instead of JSON (wrong URL)
**Solution:**
1. Verify the URL in `api_config.dart`
2. Check that you're using port 3000, not 5000
3. Ensure `/api` prefix is included where needed

### Issue 3: "buyer has insufficient TEC balance"
**This is expected!** The blockchain is working correctly.
**Solution:**
1. New factories start with 0 TEC balance
2. First mint energy tokens: `/api/energy/mint`
3. Then you can create trades

### Issue 4: Connection timeout
**Solution:**
1. Increase timeout in `api_config.dart`
2. Check blockchain network is running: `docker ps`
3. Restart chaincode containers if needed

### Issue 5: "channel 'energychannel' not found"
**Solution:**
The channel name is `energychannel`, not `mychannel`. Backend is configured correctly.

## Testing Checklist

Before deploying, test these scenarios:

- [ ] Factory registration works
- [ ] Login works with correct credentials
- [ ] Can view list of factories
- [ ] Can mint energy tokens
- [ ] Can create energy trade
- [ ] Can execute trade (with sufficient balance)
- [ ] Error handling shows proper messages
- [ ] App works on target device (emulator/physical)

## Production Deployment

For production deployment:

1. **Update API URLs** - Use domain name instead of IP
2. **Enable HTTPS** - Set up SSL certificates
3. **Add Authentication** - Implement JWT tokens
4. **Error Logging** - Add proper error tracking
5. **Load Balancing** - Scale backend if needed

## Quick Start Commands

```bash
# 1. Start blockchain backend
cd "c:\premieretsyp\energy-trading-network\application"
node app.js

# 2. In a new terminal, run Flutter app
cd "c:\premieretsyp\mobile app\flutter_application_1"
flutter run -d chrome

# 3. Test registration in app or via curl:
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "factory_name": "Test Factory",
    "email": "test@example.com",
    "password": "password123",
    "fiscal_matricule": "FM-TEST-001",
    "localisation": "Test Location",
    "energy_capacity": 1000,
    "contact_info": "+216-123-456",
    "energy_source": "solar"
  }'
```

## Support

If you encounter issues:
1. Check the backend logs in the terminal
2. Check Flutter console for error messages
3. Verify Docker containers are running
4. Test API endpoints with curl first
5. Check firewall settings

## Next Steps

✅ Backend is connected
✅ Chaincode is deployed and tested
✅ Mobile app is configured

Now you can:
1. Customize the UI
2. Add more features
3. Implement real-time updates
4. Add push notifications
5. Deploy to production
