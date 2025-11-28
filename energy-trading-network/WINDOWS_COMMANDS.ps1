# Windows PowerShell Commands for Energy Trading Network
# Use these commands if you prefer PowerShell over Git Bash
# 
# Current workspace: C:\premieretsyp
# Project structure:
#   C:\premieretsyp\energy-trading-network\  (this project)
#   C:\premieretsyp\fabric-samples\          (Hyperledger Fabric)

# ============================================
# SETUP COMMANDS
# ============================================

# Navigate to network directory
# cd energy-trading-network\network

# Start network (using Git Bash from PowerShell)
# & "C:\Program Files\Git\bin\bash.exe" -c "./startNetwork.sh"

# Deploy chaincode
# & "C:\Program Files\Git\bin\bash.exe" -c "./deployChaincode.sh"

# Stop network
# & "C:\Program Files\Git\bin\bash.exe" -c "./stopNetwork.sh"

# ============================================
# DOCKER COMMANDS
# ============================================

# Check running containers
# docker ps

# View peer logs
# docker logs peer0.org1.example.com -f

# View orderer logs
# docker logs orderer.example.com -f

# Stop all containers
# docker stop $(docker ps -aq)

# Clean up Docker
# docker system prune -f

# ============================================
# APPLICATION COMMANDS
# ============================================

# Navigate to application directory
# cd energy-trading-network\application

# Install dependencies (first time only)
# npm install

# Enroll admin (first time only)
# node enrollAdmin.js

# Start API server
# npm start

# ============================================
# API TESTING COMMANDS (Using Invoke-WebRequest)
# ============================================

# Test API health
# Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method Get

# Register a new factory
# $body = @{
#     factoryId = "Factory20"
#     name = "PowerShell Test Factory"
#     initialBalance = 800
#     energyType = "solar"
# } | ConvertTo-Json
# Invoke-RestMethod -Uri "http://localhost:3000/api/factory/register" -Method Post -Body $body -ContentType "application/json"

# Mint energy tokens
# $body = @{
#     factoryId = "Factory01"
#     amount = 250
# } | ConvertTo-Json
# Invoke-RestMethod -Uri "http://localhost:3000/api/energy/mint" -Method Post -Body $body -ContentType "application/json"

# Transfer energy
# $body = @{
#     fromFactoryId = "Factory01"
#     toFactoryId = "Factory02"
#     amount = 100
# } | ConvertTo-Json
# Invoke-RestMethod -Uri "http://localhost:3000/api/energy/transfer" -Method Post -Body $body -ContentType "application/json"

# Create trade
# $body = @{
#     tradeId = "TRADE001"
#     sellerId = "Factory01"
#     buyerId = "Factory03"
#     amount = 150
#     pricePerUnit = 0.05
# } | ConvertTo-Json
# Invoke-RestMethod -Uri "http://localhost:3000/api/trade/create" -Method Post -Body $body -ContentType "application/json"

# Execute trade
# $body = @{
#     tradeId = "TRADE001"
# } | ConvertTo-Json
# Invoke-RestMethod -Uri "http://localhost:3000/api/trade/execute" -Method Post -Body $body -ContentType "application/json"

# Get factory info
# Invoke-RestMethod -Uri "http://localhost:3000/api/factory/Factory01" -Method Get

# Get factory balance
# Invoke-RestMethod -Uri "http://localhost:3000/api/factory/Factory01/balance" -Method Get

# Get all factories
# Invoke-RestMethod -Uri "http://localhost:3000/api/factories" -Method Get

# Get trade info
# Invoke-RestMethod -Uri "http://localhost:3000/api/trade/TRADE001" -Method Get

# ============================================
# USEFUL TIPS
# ============================================

# Open CouchDB in browser
# Start-Process "http://localhost:5984/_utils/"
# Login: admin / adminpw

# Open API in browser
# Start-Process "http://localhost:3000/api/health"

# View current directory structure
# Get-ChildItem -Recurse -Directory | Select-Object FullName

# Check if Docker is running
# docker info

# Check if Node.js is installed
# node --version
# npm --version

# Check if Go is installed
# go version
