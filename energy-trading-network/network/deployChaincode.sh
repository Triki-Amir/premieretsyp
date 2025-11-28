#!/bin/bash

# Deploy Chaincode Script for Energy Trading Network
# This script packages, installs, and deploys the energy token smart contract

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHANNEL_NAME="energychannel"
CHAINCODE_NAME="energytoken"
CHAINCODE_VERSION="1.1"
CHAINCODE_SEQUENCE=1
CHAINCODE_PATH="$(cd "$(dirname "$0")/../chaincode" && pwd)"

# Print colored message
printMessage() {
  echo -e "${BLUE}"
  echo "=========================================="
  echo "$1"
  echo "=========================================="
  echo -e "${NC}"
}

printSuccess() {
  echo -e "${GREEN}✓ $1${NC}"
}

printError() {
  echo -e "${RED}✗ $1${NC}"
}

# Set environment for peer operations
setEnvironment() {
  # Add Fabric binaries to PATH
  export PATH=/mnt/c/premieretsyp/fabric-samples/bin:$PATH
  export FABRIC_CFG_PATH=/mnt/c/premieretsyp/fabric-samples/config
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=/mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

# Set environment for Org2 peer operations
setEnvironmentOrg2() {
  export PATH=/mnt/c/premieretsyp/fabric-samples/bin:$PATH
  export FABRIC_CFG_PATH=/mnt/c/premieretsyp/fabric-samples/config
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=/mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=/mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}

printMessage "Deploying Energy Token Chaincode"

# Set environment
setEnvironment

# Show chaincode path for debugging
echo "Chaincode path: ${CHAINCODE_PATH}"
echo ""

# Step 1: Package the chaincode
printMessage "Step 1: Packaging Chaincode"
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
  --path ${CHAINCODE_PATH} \
  --lang golang \
  --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

if [ $? -eq 0 ]; then
  printSuccess "Chaincode packaged successfully"
else
  printError "Failed to package chaincode"
  exit 1
fi

# Step 2: Install chaincode on Org1 peer
printMessage "Step 2: Installing Chaincode on Org1 Peer"
setEnvironment
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 2>&1 | tee install_output.txt
INSTALL_STATUS=${PIPESTATUS[0]}

# Check if installation succeeded or if chaincode is already installed
if grep -q "chaincode already successfully installed" install_output.txt || grep -q "Installed remotely" install_output.txt; then
  printSuccess "Chaincode installed on Org1 successfully"
else
  printError "Failed to install chaincode on Org1"
  exit 1
fi

rm -f install_output.txt

# Wait for installation
sleep 3

# Step 3: Query installed chaincode to get package ID
printMessage "Step 3: Querying Installed Chaincode"
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep ${CHAINCODE_NAME}_${CHAINCODE_VERSION} | sed 's/.*Package ID: \(.*\), Label.*/\1/')

if [ -z "$PACKAGE_ID" ]; then
  printError "Failed to get package ID"
  exit 1
fi

echo "Package ID: $PACKAGE_ID"
printSuccess "Package ID retrieved"

# Step 4: Approve chaincode for Org1
printMessage "Step 4: Approving Chaincode for Org1"
setEnvironment
peer lifecycle chaincode approveformyorg \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --package-id ${PACKAGE_ID} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile /mnt/c/premieretsyp/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -eq 0 ]; then
  printSuccess "Chaincode approved for Org1"
else
  printError "Failed to approve chaincode for Org1"
  exit 1
fi

sleep 3

# Step 5: Install chaincode on Org2 peer
printMessage "Step 5: Installing Chaincode on Org2 Peer"
setEnvironmentOrg2
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 2>&1 | tee install_output_org2.txt

if grep -q "chaincode already successfully installed" install_output_org2.txt || grep -q "Installed remotely" install_output_org2.txt; then
  printSuccess "Chaincode installed on Org2 successfully"
else
  printError "Failed to install chaincode on Org2"
  exit 1
fi

rm -f install_output_org2.txt
sleep 3

# Step 6: Approve chaincode for Org2
printMessage "Step 6: Approving Chaincode for Org2"
setEnvironmentOrg2
peer lifecycle chaincode approveformyorg \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --package-id ${PACKAGE_ID} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile /mnt/c/premieretsyp/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

if [ $? -eq 0 ]; then
  printSuccess "Chaincode approved for Org2"
else
  printError "Failed to approve chaincode for Org2"
  exit 1
fi

sleep 3

# Step 7: Check commit readiness
printMessage "Step 7: Checking Commit Readiness"
setEnvironment
peer lifecycle chaincode checkcommitreadiness \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile /mnt/c/premieretsyp/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --output json

printSuccess "Commit readiness checked"

# Step 8: Commit chaincode definition with both Org1 and Org2
printMessage "Step 8: Committing Chaincode Definition"
setEnvironment
peer lifecycle chaincode commit \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --channelID ${CHANNEL_NAME} \
  --name ${CHAINCODE_NAME} \
  --version ${CHAINCODE_VERSION} \
  --sequence ${CHAINCODE_SEQUENCE} \
  --tls \
  --cafile /mnt/c/premieretsyp/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles /mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles /mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

if [ $? -eq 0 ]; then
  printSuccess "Chaincode committed successfully"
else
  printError "Failed to commit chaincode"
  exit 1
fi

# Wait for commit
sleep 5

# Step 9: Initialize the ledger
printMessage "Step 9: Initializing Ledger"
setEnvironment
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile /mnt/c/premieretsyp/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C ${CHANNEL_NAME} \
  -n ${CHAINCODE_NAME} \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles /mnt/c/premieretsyp/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  -c '{"function":"InitLedger","Args":[]}'

if [ $? -eq 0 ]; then
  printSuccess "Ledger initialized with sample factories"
else
  printError "Failed to initialize ledger"
  exit 1
fi

printMessage "Chaincode Deployment Complete!"
echo ""
echo "Available functions:"
echo "  - InitLedger: Initialize with sample factories"
echo "  - RegisterFactory: Register a new factory"
echo "  - MintEnergyTokens: Generate energy tokens"
echo "  - TransferEnergy: Transfer tokens between factories"
echo "  - CreateEnergyTrade: Create a trade transaction"
echo "  - ExecuteTrade: Complete a trade"
echo "  - GetFactory: Query factory information"
echo "  - GetEnergyBalance: Get factory's token balance"
echo "  - GetAllFactories: List all factories"
echo ""
echo "Example query:"
echo 'peer chaincode query -C energychannel -n energytoken -c '"'"'{"Args":["GetAllFactories"]}'"'"
