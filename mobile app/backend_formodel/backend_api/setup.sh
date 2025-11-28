#!/bin/bash
# Quick start script for NILM Backend API

echo "======================================"
echo "🚀 NILM Backend API - Quick Start"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}Step 1: Installing Node.js dependencies...${NC}"
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install Node.js dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js dependencies installed${NC}"

echo -e "\n${YELLOW}Step 2: Setting up Python environment...${NC}"
cd python_service
if [ ! -d "venv" ]; then
    python -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${GREEN}✅ Virtual environment already exists${NC}"
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install Python dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python dependencies installed${NC}"

cd ..

echo -e "\n${GREEN}======================================"
echo "✅ Setup Complete!"
echo "======================================"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Copy .env.example to .env and configure:"
echo "   cp .env.example .env"
echo ""
echo "2. Start the Python Flask service:"
echo "   cd python_service"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "   venv\\Scripts\\activate"
else
    echo "   source venv/bin/activate"
fi
echo "   python model_service.py"
echo ""
echo "3. In another terminal, start Express API:"
echo "   npm start"
echo ""
echo "4. Test the API:"
echo "   curl http://localhost:3000/api/health"
echo -e "\n${GREEN}For more details, see README.md${NC}"
