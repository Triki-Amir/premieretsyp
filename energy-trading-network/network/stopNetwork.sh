#!/bin/bash

# Stop Energy Trading Network Script
# This script stops and cleans up the blockchain network

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

printMessage "Stopping Energy Trading Network"

# Stop custom docker-compose network (if running)
echo "Stopping custom network containers..."
docker-compose -f docker-compose.yml down --volumes --remove-orphans 2>/dev/null

# Stop fabric-samples test-network
echo "Stopping fabric-samples test-network..."
cd ../../fabric-samples/test-network
./network.sh down
cd ../../energy-trading-network/network

printSuccess "Network stopped"

# Clean up chaincode package
rm -f *.tar.gz

printSuccess "Cleanup complete"

printMessage "Energy Trading Network Stopped Successfully!"
