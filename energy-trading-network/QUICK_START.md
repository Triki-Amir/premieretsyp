# 🎯 Quick Start Guide - C:\premieretsyp

## ✅ Your Folder Structure is Correct!

```
C:\premieretsyp\
├── energy-trading-network\  ← Your project ✓
└── fabric-samples\          ← Hyperledger Fabric ✓
```

## 🚀 Start Your Network (3 Steps)

### Step 1: Start Docker Desktop
- Open Docker Desktop and wait for it to say "Running"

### Step 2: Open Git Bash (or WSL)
```bash
cd /mnt/c/premieretsyp/energy-trading-network/network
./startNetwork.sh
./deployChaincode.sh
```

### Step 3: Start the API
```bash
cd ../application
npm install              # First time only
node enrollAdmin.js      # First time only
npm start
```

## 🌐 Access Your Network

- **API**: http://localhost:3000/api/health
- **All Factories**: http://localhost:3000/api/factories
- **CouchDB**: http://localhost:5984/_utils/ (admin/adminpw)

## 📋 Quick Test

### Test 1: Check if network is running
```bash
curl http://localhost:3000/api/health
```

### Test 2: View all factories
```bash
curl http://localhost:3000/api/factories
```

### Test 3: Mint some energy tokens
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId":"Factory01","amount":250}'
```

### Test 4: Check updated balance
```bash
curl http://localhost:3000/api/factory/Factory01/balance
```

## 🛑 Stop the Network

```bash
cd /mnt/c/premieretsyp/energy-trading-network/network
./stopNetwork.sh
```

## 📚 Documentation Files

All in `C:\premieretsyp\energy-trading-network\`:

- **README.md** - Complete guide with all features
- **GETTING_STARTED.md** - Step-by-step first-time setup
- **QUICK_REFERENCE.md** - All commands and API examples
- **ARCHITECTURE.md** - System design and flow diagrams
- **SCENARIOS.md** - 10 real-world usage scenarios
- **FOLDER_STRUCTURE.md** - Complete directory breakdown
- **PATH_UPDATE_SUMMARY.md** - Path configuration details
- **WINDOWS_COMMANDS.ps1** - PowerShell command reference

## 💡 Pro Tips

1. **Use Git Bash**: Works better than PowerShell for shell scripts
2. **Keep Docker Running**: Network requires Docker to be active
3. **One Terminal per Service**: Run network in one, API in another
4. **Check Logs**: Use `docker logs <container-name> -f` to debug
5. **CouchDB is Visual**: Great for seeing blockchain data

## 🐛 Quick Troubleshooting

### Network won't start?
```bash
./stopNetwork.sh
docker system prune -f
./startNetwork.sh
```

### API connection errors?
```bash
cd ../application
rm -rf wallet node_modules
npm install
node enrollAdmin.js
```

### Check if containers are running
```bash
docker ps
```

## 🎉 You're All Set!

Your project is at: **`C:\premieretsyp\energy-trading-network`**

Everything is configured correctly and ready to run! 🚀⚡
