#!/bin/bash

# Start Energy Trading Network Script
# This script starts the blockchain network for the industrial zone

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  printError "Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

printMessage "Starting Energy Trading Network"

# Generate crypto materials and start the test-network
printMessage "Starting Fabric Test Network"
# We use the fabric-samples test-network which creates:
# - orderer.example.com (port 7050)
# - peer0.org1.example.com (port 7051)
# - peer0.org2.example.com (port 9051)
# - energychannel
cd ../../fabric-samples/test-network
./network.sh up createChannel -ca -c energychannel -s couchdb

if [ $? -ne 0 ]; then
  printError "Failed to start network"
  exit 1
fi

cd ../../energy-trading-network/network
printSuccess "Network started successfully"

# Wait for network to stabilize
echo "Waiting for network to initialize..."
sleep 5

# Check if containers are running
printMessage "Checking Container Status"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "peer0.org1|orderer.example|couch"

printMessage "Energy Trading Network Started Successfully!"
echo ""
echo "Network endpoints:"
echo "  - Orderer: localhost:7050 (orderer.example.com)"
echo "  - Peer Org1: localhost:7051 (peer0.org1.example.com)"
echo "  - Peer Org2: localhost:9051 (peer0.org2.example.com)"
echo "  - CouchDB Org1: http://localhost:5984/_utils/ (admin/adminpw)"
echo "  - CouchDB Org2: http://localhost:7984/_utils/ (admin/adminpw)"
echo ""
echo "Channel 'energychannel' created successfully"
echo ""
echo "Next steps:"
echo "  1. Deploy the chaincode: ./deployChaincode.sh"
echo "  2. Set up application: cd ../application && npm install && node enrollAdmin.js"
echo "  3. Run the application: npm start"
