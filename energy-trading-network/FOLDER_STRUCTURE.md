# Folder Structure - Energy Trading Network

## ✅ Current Setup

Your project is correctly located at: **`C:\premieretsyp`**

## 📂 Complete Directory Structure

```
C:\premieretsyp\
│
├── energy-trading-network\          ← Your Energy Trading Project
│   ├── application\                 ← Node.js REST API
│   │   ├── app.js                   - Main API server
│   │   ├── enrollAdmin.js           - Admin enrollment
│   │   ├── create-connection-profile.js
│   │   ├── package.json
│   │   └── wallet\                  - User identities (auto-generated)
│   │
│   ├── chaincode\                   ← Smart Contract (Go)
│   │   ├── energyToken.go           - Main chaincode
│   │   └── go.mod                   - Go dependencies
│   │
│   ├── network\                     ← Blockchain Network Scripts
│   │   ├── docker-compose.yml       - Container configuration
│   │   ├── startNetwork.sh          - Start the network
│   │   ├── stopNetwork.sh           - Stop the network
│   │   ├── deployChaincode.sh       - Deploy smart contract
│   │   ├── networkSetup.sh          - Channel setup
│   │   ├── channel-artifacts\       - Channel configuration
│   │   └── organizations\           - Certificates (auto-generated)
│   │
│   └── Documentation Files
│       ├── README.md                - Complete guide
│       ├── GETTING_STARTED.md       - Quick start guide
│       ├── QUICK_REFERENCE.md       - Command cheat sheet
│       ├── ARCHITECTURE.md          - System diagrams
│       ├── SCENARIOS.md             - Usage examples
│       ├── WINDOWS_COMMANDS.ps1     - PowerShell commands
│       └── FOLDER_STRUCTURE.md      - This file
│
└── fabric-samples\                  ← Hyperledger Fabric Test Network
    ├── bin\                         - Fabric binaries (peer, orderer, etc.)
    ├── config\                      - Fabric configuration files
    ├── test-network\                - Base network infrastructure
    │   ├── organizations\           - Crypto materials
    │   │   ├── ordererOrganizations\
    │   │   └── peerOrganizations\
    │   ├── network.sh               - Network management script
    │   └── docker\                  - Docker configurations
    └── ... (other sample projects)
```

## 🔗 How the Projects Interact

### 1. **Fabric Samples (Base Infrastructure)**
   - Location: `C:\premieretsyp\fabric-samples\`
   - Provides: Base Hyperledger Fabric network, binaries, and crypto materials
   - Used by: The energy trading network scripts reference this

### 2. **Energy Trading Network (Your Project)**
   - Location: `C:\premieretsyp\energy-trading-network\`
   - Provides: Custom smart contract and API for energy trading
   - Uses: Fabric samples for network infrastructure

## 📝 Path References in Scripts

All scripts use **relative paths** from the project root, which work correctly:

### In `startNetwork.sh`:
```bash
cd ../../fabric-samples/test-network
./network.sh up createChannel -ca -c energychannel
cd ../../energy-trading-network/network
```

### In `deployChaincode.sh`:
```bash
export PATH=${PWD}/../../fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../../fabric-samples/config
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../../fabric-samples/test-network/...
```

### In Application Files (`app.js`, `enrollAdmin.js`):
```javascript
const ccpPath = path.resolve(__dirname, '..', '..', 'fabric-samples', 
    'test-network', 'organizations', 'peerOrganizations', 
    'org1.example.com', 'connection-org1.json');
```

## ✅ All Paths Are Correct

The folder structure is **already set up correctly** for the name `C:\premieretsyp`:

1. ✅ Energy trading project references fabric-samples using relative paths
2. ✅ All scripts navigate correctly between directories
3. ✅ Application connects to the right network configuration
4. ✅ Chaincode deployment uses correct certificate paths

## 🚀 Ready to Use

You can now:

1. **Start the network:**
   ```bash
   cd C:\premieretsyp\energy-trading-network\network
   ./startNetwork.sh
   ```

2. **Deploy chaincode:**
   ```bash
   ./deployChaincode.sh
   ```

3. **Run the application:**
   ```bash
   cd ../application
   npm install
   node enrollAdmin.js
   npm start
   ```

## 📌 Important Notes

- The folder name `C:\premieretsyp` is correctly configured in all scripts
- All relative paths (`../../fabric-samples/...`) work from this structure
- No hardcoded paths need to be changed
- The project is ready to run as-is

## 🛠️ If You Need to Move the Project

If you ever need to move the project to a different location:

1. Move **both folders together**:
   - `energy-trading-network\`
   - `fabric-samples\`

2. Keep them in the **same parent directory**

3. The relative paths will continue to work correctly

---

**Your project structure is correct and ready to use!** 🎉
