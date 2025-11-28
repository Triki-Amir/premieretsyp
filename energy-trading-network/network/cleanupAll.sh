#!/bin/bash

# Complete Cleanup Script
# This script stops all networks and removes all containers, volumes, and artifacts

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

printMessage "Complete Network Cleanup"

# Stop custom energy network
echo "Stopping custom energy trading network..."
cd "$(dirname "$0")"
docker-compose -f docker-compose.yml down --volumes --remove-orphans 2>/dev/null
printSuccess "Custom network stopped"

# Stop fabric-samples test-network
echo "Stopping fabric-samples test-network..."
cd ../../fabric-samples/test-network
./network.sh down 2>/dev/null
printSuccess "Test network stopped"

# Remove all Hyperledger containers
echo "Removing all Hyperledger containers..."
docker rm -f $(docker ps -aq -f "name=peer*" -f "name=orderer*" -f "name=ca_*" -f "name=cli" -f "name=couchdb") 2>/dev/null
printSuccess "Containers removed"

# Prune volumes
echo "Removing volumes..."
docker volume prune -f
printSuccess "Volumes removed"

# Remove chaincode packages
cd ../../energy-trading-network/network
rm -f *.tar.gz 2>/dev/null
printSuccess "Chaincode packages removed"

# Remove channel artifacts from test-network
cd ../../fabric-samples/test-network
rm -rf channel-artifacts/*.block 2>/dev/null
rm -rf system-genesis-block/*.block 2>/dev/null
printSuccess "Channel artifacts cleaned"

printMessage "Cleanup Complete!"
echo ""
echo "You can now start fresh with:"
echo "  ./startNetwork.sh"
