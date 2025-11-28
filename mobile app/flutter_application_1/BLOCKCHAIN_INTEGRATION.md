# Blockchain Integration Guide

## ✅ Integration Complete

Your Flutter app is now fully integrated with the Hyperledger Fabric blockchain backend!

## 🎯 Features Implemented

### 1. **Home Page Dashboard** (`dashboard_screen_blockchain.dart`)
- ✅ Real-time blockchain connection status indicator
- ✅ Search bar to filter factories by name
- ✅ Factory cards displaying:
  - Available energy (kWh)
  - Daily consumption (kWh/day)
  - Price per unit ($/kWh)
  - Energy status badge (SURPLUS/DEFICIT)
  - Total capacity from all sources
- ✅ Buy/Sell action buttons based on factory status
- ✅ Factory details modal with complete information

### 2. **Blockchain API Service** (`blockchain_api_service.dart`)
- ✅ Platform-aware base URL (Android emulator: `10.0.2.2`, Desktop: `localhost`)
- ✅ Complete API integration:
  - `GET /factories` - List all registered factories
  - `GET /factory/:id` - Get specific factory details
  - `GET /factory/:id/energy-status` - Check surplus/deficit status
  - `POST /trade/create` - Create new energy trade
  - `POST /trade/execute` - Execute pending trade
  - Health check endpoint

### 3. **State Management** (`energy_data_provider.dart`)
- ✅ Automatic blockchain connection monitoring
- ✅ Factory data syncing from blockchain
- ✅ Buy/Sell energy methods
- ✅ Graceful fallback to demo data if blockchain unavailable
- ✅ Real-time updates with Provider pattern

### 4. **Data Models** (`factory.dart`)
- ✅ Extended Factory model with blockchain fields:
  - `energyType` - Type of energy (solar/wind/mixed)
  - `dailyConsumption` - Daily energy consumption (kWh)
  - `availableEnergy` - Current available energy (kWh)
  - `currencyBalance` - Factory currency balance ($)
  - `pricePerUnit` - Energy price per kWh ($)
- ✅ `fromBlockchain()` constructor for API JSON parsing
- ✅ Automatic status calculation (surplus/deficit/balanced)

### 5. **Android Configuration**
- ✅ Internet permission added to AndroidManifest.xml

## 🚀 Testing Instructions

### Step 1: Start Blockchain Backend
```bash
# Terminal 1: Start Hyperledger Fabric network
cd C:\premieretsyp\energy-trading-network\network
./startNetwork.sh

# Terminal 2: Start Node.js API server
cd C:\premieretsyp\energy-trading-network\application
node app.js
```

Verify API is running: http://localhost:3000/health

### Step 2: Run Flutter App

**Option A: Android Emulator**
```powershell
cd "C:\premieretsyp\mobile app\flutter_application_1"
flutter run
```

**Option B: Desktop (Windows)**
```powershell
cd "C:\premieretsyp\mobile app\flutter_application_1"
flutter run -d windows
```

### Step 3: Test Features

1. **Login** with any credentials
2. **Check connection status** - Look for green cloud icon in app bar
3. **Search factories** - Type factory name in search bar
4. **View factory details** - Click "Details" button on any factory card
5. **Buy energy** (from SURPLUS factories):
   - Click "Buy Energy" button
   - Enter amount in kWh
   - Confirm trade
   - Check toast notification for success/error
6. **Sell energy** (to DEFICIT factories):
   - Click "Sell Energy" button
   - Enter amount in kWh
   - Confirm offer
   - Check toast notification

## 📡 Network Configuration

### Android Emulator
- Base URL: `http://10.0.2.2:3000`
- `10.0.2.2` is the special IP that maps to host machine's `localhost`

### Desktop/Chrome
- Base URL: `http://localhost:3000`

The app automatically detects the platform and uses the correct URL.

## 🔍 Troubleshooting

### "Not connected to blockchain" banner appears
- Ensure Node.js API is running on port 3000
- Check `http://localhost:3000/health` in browser
- Verify Hyperledger Fabric network is running
- Check console logs for connection errors

### "No factories available"
- Register factories through blockchain network
- Check API endpoint: `http://localhost:3000/factories`
- App falls back to demo data if API unavailable

### Buy/Sell buttons not working
- Ensure blockchain network is running
- Check trade endpoints in app.js are accessible
- Verify factory has correct status (surplus/deficit)
- Check console for error messages

## 📝 API Endpoints Used

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/health` | Check API health |
| GET | `/factories` | Get all registered factories |
| GET | `/factory/:id` | Get specific factory |
| GET | `/factory/:id/energy-status` | Get surplus/deficit status |
| POST | `/trade/create` | Create energy trade |
| POST | `/trade/execute` | Execute trade |

## 🎨 UI Components

### Factory Card Layout
```
┌─────────────────────────────────────┐
│ Factory Name            [SURPLUS]   │
│ SOLAR                               │
│                                     │
│ Available   Consumption    Price    │
│ 150 kWh     100 kWh/day   $0.10/kWh │
│                                     │
│ 🔋 Total Capacity: 500 kWh         │
│                                     │
│ [Buy Energy]  [Details]             │
└─────────────────────────────────────┘
```

### Status Badge Colors
- 🟢 **Green** - SURPLUS (availableEnergy > dailyConsumption)
- 🔴 **Red** - DEFICIT (availableEnergy < dailyConsumption)

## 🔄 Data Flow

```
Blockchain (Fabric) → app.js (API) → BlockchainApiService → EnergyDataProvider → UI (Dashboard)
```

## 📦 Dependencies
- `http: ^1.2.1` - HTTP client for API calls
- `provider: ^6.1.1` - State management
- `fluttertoast: ^8.2.8` - Toast notifications

## 🎯 Next Steps

1. Test complete buy/sell flow with real blockchain
2. Add transaction history screen
3. Implement real-time price updates
4. Add push notifications for trade completion
5. Create analytics dashboard with trade metrics

## 📚 File Structure

```
lib/
├── main.dart                              # App entry, uses DashboardScreenNew
├── models/
│   └── factory.dart                       # Extended with blockchain fields
├── providers/
│   └── energy_data_provider.dart         # Blockchain integration
├── services/
│   └── blockchain_api_service.dart       # HTTP API client
└── screens/
    └── dashboard_screen_blockchain.dart  # New blockchain dashboard
```

## ✨ Success Indicators

- ✅ App bar shows green cloud icon
- ✅ Factories display with real blockchain data
- ✅ Status badges show correct surplus/deficit
- ✅ Buy/Sell buttons appear based on factory status
- ✅ Toast notifications confirm trade actions
- ✅ Details modal shows complete factory info

---

**Integration Status:** ✅ Complete and ready for testing!

**Last Updated:** January 2025
