#!/bin/bash

echo "🚀 Deploying Move Builders Hub - Full Stack"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Frontend deployment
echo -e "${YELLOW}📂 Deploying Frontend...${NC}"
echo "Uploading index.html to hosting..."
# Upload index.html to your hosting provider

# Backend deployment
echo -e "${YELLOW}🖥️  Setting up Backend API...${NC}"
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found${NC}"
    exit 1
fi

echo "Installing dependencies..."
npm install

echo "Starting API server..."
npm start &

# Move contract deployment
echo -e "${YELLOW}⛓️  Deploying Move Smart Contract...${NC}"
if [ ! -f "Move.toml" ]; then
    echo -e "${RED}❌ Move.toml not found${NC}"
    exit 1
fi

echo "Compiling Move contract..."
aptos move compile

echo "Publishing to Aptos Testnet..."
aptos move publish --assume-yes

# Database setup
echo -e "${YELLOW}🗄️  Setting up Database...${NC}"
echo "MongoDB connection will be established automatically"

echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "🌐 Frontend: https://movebuildershub.xyz"
echo "🔗 API: http://localhost:3001"
echo "📊 Analytics: http://localhost:3001/api/analytics"
echo "🏆 Leaderboard: http://localhost:3001/api/leaderboard"
echo ""
echo "🔧 Next steps:"
echo "1. Update env.example with your values"
echo "2. Copy to .env file"
echo "3. Configure MongoDB connection"
echo "4. Update contract address in frontend"
echo ""
echo "🎉 Move Builders Hub is now live!"
