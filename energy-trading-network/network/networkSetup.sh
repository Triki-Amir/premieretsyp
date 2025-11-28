#!/bin/bash

# Network Configuration Script for Energy Trading Network
# This script sets up the Hyperledger Fabric network for the industrial zone

# Set environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/energyzone.com/orderers/orderer.energyzone.com/msp/tlscacerts/tlsca.energyzone.com-cert.pem
export PEER0_INDUSTRIAL_CA=${PWD}/organizations/peerOrganizations/industrial.energyzone.com/peers/peer0.industrial.energyzone.com/tls/ca.crt

# Set peer environment for Industrial organization
setIndustrialEnv() {
  export CORE_PEER_LOCALMSPID="IndustrialMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_INDUSTRIAL_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/industrial.energyzone.com/users/Admin@industrial.energyzone.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

# Print message with formatting
printMessage() {
  echo ""
  echo "=========================================="
  echo "$1"
  echo "=========================================="
  echo ""
}

# Function to create channel
createChannel() {
  printMessage "Creating Energy Trading Channel"
  
  setIndustrialEnv
  
  # Create channel
  peer channel create -o localhost:7050 \
    -c energychannel \
    -f ./channel-artifacts/energychannel.tx \
    --outputBlock ./channel-artifacts/energychannel.block \
    --tls --cafile $ORDERER_CA
  
  if [ $? -eq 0 ]; then
    echo "✓ Channel created successfully"
  else
    echo "✗ Failed to create channel"
    exit 1
  fi
}

# Function to join channel
joinChannel() {
  printMessage "Joining Peer to Channel"
  
  setIndustrialEnv
  
  # Join peer to channel
  peer channel join -b ./channel-artifacts/energychannel.block
  
  if [ $? -eq 0 ]; then
    echo "✓ Peer joined channel successfully"
  else
    echo "✗ Failed to join channel"
    exit 1
  fi
}

# Function to update anchor peers
updateAnchorPeers() {
  printMessage "Updating Anchor Peers"
  
  setIndustrialEnv
  
  # Update anchor peer
  peer channel update -o localhost:7050 \
    -c energychannel \
    -f ./channel-artifacts/IndustrialMSPanchors.tx \
    --tls --cafile $ORDERER_CA
  
  if [ $? -eq 0 ]; then
    echo "✓ Anchor peers updated successfully"
  else
    echo "✗ Failed to update anchor peers"
    exit 1
  fi
}

# Main execution
printMessage "Setting up Energy Trading Network"

createChannel
sleep 2

joinChannel
sleep 2

updateAnchorPeers

printMessage "Network Setup Complete!"
