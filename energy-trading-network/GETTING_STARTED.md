# 🚀 Getting Started - Energy Trading Network

## What You Have

A complete Hyperledger Fabric blockchain network for energy trading between factories with:

✅ **Smart Contract** (Go) - Energy token management and trading logic  
✅ **Network Infrastructure** - Docker containers, orderer, peer, database  
✅ **REST API** (Node.js) - Easy-to-use HTTP endpoints  
✅ **Complete Documentation** - Guides, examples, and architecture diagrams

## 📂 Your Workspace Location

Your project is located at: `C:\premieretsyp\`

This folder contains:
- `energy-trading-network\` - Your energy trading blockchain project
- `fabric-samples\` - Hyperledger Fabric test network and tools  

## 📁 Project Structure

```
energy-trading-network/
├── README.md                    ⭐ Start here - Complete guide
├── QUICK_REFERENCE.md           ⚡ Quick commands and examples
├── ARCHITECTURE.md              📊 System architecture diagrams
├── SCENARIOS.md                 💡 Real-world usage examples
├── WINDOWS_COMMANDS.ps1         🪟 PowerShell commands for Windows
│
├── chaincode/                   🔗 Smart Contract
│   ├── energyToken.go          - Main smart contract (well-commented)
│   └── go.mod                  - Go dependencies
│
├── network/                     🌐 Blockchain Network
│   ├── docker-compose.yml      - Network infrastructure
│   ├── startNetwork.sh         - Start the network
│   ├── stopNetwork.sh          - Stop the network
│   ├── deployChaincode.sh      - Deploy smart contract
│   └── networkSetup.sh         - Channel configuration
│
└── application/                 💻 Client Application
    ├── app.js                  - REST API server
    ├── enrollAdmin.js          - Admin setup
    ├── package.json            - Node.js dependencies
    └── wallet/                 - User identities (auto-created)
```

## 🎯 First Time Setup (5 Steps)

### Step 1: Start Docker Desktop
- Open Docker Desktop
- Wait until it says "Docker is running"

### Step 2: Start the Network (Git Bash)
```bash
cd energy-trading-network/network
./startNetwork.sh
```

**Expected Output:**
```
========================================
Starting Energy Trading Network
========================================
✓ Cleanup complete
✓ Certificates generated
✓ Docker containers started
✓ Network endpoints:
  - Orderer: localhost:7050
  - Peer: localhost:7051
  - CouchDB UI: http://localhost:5984/_utils/
```

### Step 3: Deploy Smart Contract (Git Bash)
```bash
./deployChaincode.sh
```

**Expected Output:**
```
========================================
Deploying Energy Token Chaincode
========================================
✓ Chaincode packaged successfully
✓ Chaincode installed successfully
✓ Chaincode approved successfully
✓ Chaincode committed successfully
✓ Ledger initialized with sample factories
```

### Step 4: Setup Application (PowerShell or Git Bash)
```bash
cd ../application
npm install
node enrollAdmin.js
```

**Expected Output:**
```
Wallet path: C:\...\energy-trading-network\application\wallet
✓ Successfully enrolled admin user and imported to wallet
```

### Step 5: Start API Server
```bash
npm start
```

**Expected Output:**
```
========================================
   Energy Trading Network API
========================================
Server running on http://localhost:3000

Available endpoints:
  GET  /api/health
  POST /api/factory/register
  POST /api/energy/mint
  ...
========================================
```

## ✅ Verify Everything Works

### Test 1: API Health Check
Open browser: http://localhost:3000/api/health

**Expected:**
```json
{
  "status": "OK",
  "message": "Energy Trading API is running",
  "timestamp": "2025-11-08T..."
}
```

### Test 2: View Pre-loaded Factories
Open browser: http://localhost:3000/api/factories

**Expected:** List of 5 factories

### Test 3: Check Factory Balance (using curl or PowerShell)

**Using curl (Git Bash):**
```bash
curl http://localhost:3000/api/factory/Factory01
```

**Using PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/factory/Factory01" -Method Get
```

**Expected:**
```json
{
  "success": true,
  "data": {
    "id": "Factory01",
    "name": "Solar Manufacturing Plant",
    "energyBalance": 1000,
    "energyType": "solar"
  }
}
```

### Test 4: Mint Some Energy Tokens

**Using curl:**
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId":"Factory01","amount":250}'
```

**Using PowerShell:**
```powershell
$body = @{
    factoryId = "Factory01"
    amount = 250
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/energy/mint" `
  -Method Post -Body $body -ContentType "application/json"
```

**Expected:**
```json
{
  "success": true,
  "message": "Minted 250 kWh of energy tokens for Factory01",
  "data": {
    "factoryId": "Factory01",
    "amount": 250
  }
}
```

## 🎓 Next Steps

### Learn by Example
1. Open **SCENARIOS.md** - See 10 real-world examples
2. Try the examples one by one
3. Modify amounts and IDs to experiment

### Explore the System
1. **CouchDB UI**: http://localhost:5984/_utils/
   - Login: admin / adminpw
   - View: energychannel_energytoken database
   - See all factories and trades

2. **Docker Logs**:
   ```bash
   docker logs peer0.org1.example.com -f
   ```

3. **Transaction History**:
   ```bash
   curl http://localhost:3000/api/factory/Factory01/history
   ```

### Build Your Own Scenarios

Try creating:
1. Register 15 more factories (Factory06 to Factory20)
2. Create a daily energy trading routine
3. Simulate a week of energy generation and trading
4. Generate reports and statistics

## 📚 Documentation Quick Links

- **README.md** - Complete setup guide with all details
- **QUICK_REFERENCE.md** - Command cheat sheet
- **ARCHITECTURE.md** - System diagrams and flows
- **SCENARIOS.md** - 10 detailed usage examples
- **WINDOWS_COMMANDS.ps1** - PowerShell command reference

## 🛑 When You're Done

To stop the network:
```bash
cd network
./stopNetwork.sh
```

## 🐛 Common Issues

### Issue: "Docker is not running"
**Fix:** Start Docker Desktop and wait for it to fully initialize

### Issue: "Port already in use"
**Fix:** 
```bash
./stopNetwork.sh
docker system prune -f
./startNetwork.sh
```

### Issue: "Cannot find module"
**Fix:**
```bash
cd application
rm -rf node_modules
npm install
```

### Issue: "Identity does not exist"
**Fix:**
```bash
cd application
node enrollAdmin.js
```

## 💡 Pro Tips

1. **Keep terminals open**: Run network in one terminal, API in another
2. **Use Postman**: Import API endpoints for easier testing
3. **Check CouchDB**: Visual way to see all data
4. **Read logs**: Use `docker logs` to debug issues
5. **Experiment**: Try different amounts, prices, and scenarios

## 🎉 Success Indicators

You're all set if you can:
- ✅ See "Server running on http://localhost:3000"
- ✅ Access http://localhost:3000/api/health
- ✅ View factories at http://localhost:3000/api/factories
- ✅ Mint tokens successfully
- ✅ Create and execute trades

## 📞 Need Help?

1. Check **SCENARIOS.md** for examples
2. Review **README.md** for detailed explanations
3. Check Docker container status: `docker ps`
4. View logs: `docker logs <container-name>`

## 🌟 What You Can Do Now

With this blockchain network, you can:
- ✅ Track 20+ factories' energy generation
- ✅ Trade surplus energy between factories
- ✅ Support solar, wind, and footstep power sources
- ✅ Maintain transparent, immutable records
- ✅ Query historical transactions
- ✅ Execute real-time energy trades
- ✅ Build custom applications on top of the API

---

**Ready to trade energy? Start with the scenarios in SCENARIOS.md!** 🚀⚡
