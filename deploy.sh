#!/bin/bash

# MoveHub Deployment Script
# This script deploys the MoveHub smart contracts and sets up the frontend

set -e

echo "🚀 Starting MoveHub Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if aptos CLI is installed
if ! command -v aptos &> /dev/null; then
    print_error "Aptos CLI is not installed. Please install it first."
    print_status "Visit: https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install it first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install it first."
    exit 1
fi

print_status "All prerequisites are installed ✅"

# Set up Aptos account if not exists
print_status "Setting up Aptos account..."
if ! aptos account list &> /dev/null; then
    print_warning "No Aptos account found. Creating a new account..."
    aptos init --network testnet
    print_success "Aptos account created successfully"
else
    print_success "Aptos account already exists"
fi

# Get account address
ACCOUNT_ADDRESS=$(aptos account list --query account --output table | grep -o '0x[a-fA-F0-9]*' | head -1)
print_status "Using account: $ACCOUNT_ADDRESS"

# Update Move.toml with the account address
print_status "Updating Move.toml with account address..."
sed -i "s/movehub = \"0x1\"/movehub = \"$ACCOUNT_ADDRESS\"/" Move.toml
print_success "Move.toml updated"

# Compile Move contracts
print_status "Compiling Move contracts..."
if aptos move compile; then
    print_success "Move contracts compiled successfully"
else
    print_error "Failed to compile Move contracts"
    exit 1
fi

# Run tests
print_status "Running Move tests..."
if aptos move test; then
    print_success "All tests passed ✅"
else
    print_error "Some tests failed"
    exit 1
fi

# Deploy contracts
print_status "Deploying contracts to testnet..."
if aptos move publish --named-addresses movehub=$ACCOUNT_ADDRESS; then
    print_success "Contracts deployed successfully to testnet"
else
    print_error "Failed to deploy contracts"
    exit 1
fi

# Initialize the platform
print_status "Initializing MoveHub platform..."
if aptos move run --function-id $ACCOUNT_ADDRESS::movehub::initialize; then
    print_success "MoveHub platform initialized"
else
    print_error "Failed to initialize platform"
    exit 1
fi

# Initialize rewards system
print_status "Initializing rewards system..."
if aptos move run --function-id $ACCOUNT_ADDRESS::rewards::initialize; then
    print_success "Rewards system initialized"
else
    print_error "Failed to initialize rewards system"
    exit 1
fi

# Initialize analytics system
print_status "Initializing analytics system..."
if aptos move run --function-id $ACCOUNT_ADDRESS::analytics::initialize; then
    print_success "Analytics system initialized"
else
    print_error "Failed to initialize analytics system"
    exit 1
fi

# Set up frontend
print_status "Setting up frontend..."
cd frontend

# Install dependencies
print_status "Installing frontend dependencies..."
if npm install; then
    print_success "Frontend dependencies installed"
else
    print_error "Failed to install frontend dependencies"
    exit 1
fi

# Update environment variables
print_status "Updating environment variables..."
cat > .env.local << EOF
NEXT_PUBLIC_APTOS_NETWORK=testnet
NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.testnet.aptoslabs.com
NEXT_PUBLIC_MOVEHUB_ADDRESS=$ACCOUNT_ADDRESS
EOF
print_success "Environment variables updated"

# Build frontend
print_status "Building frontend..."
if npm run build; then
    print_success "Frontend built successfully"
else
    print_error "Failed to build frontend"
    exit 1
fi

cd ..

# Create deployment summary
print_status "Creating deployment summary..."
cat > DEPLOYMENT_INFO.md << EOF
# MoveHub Deployment Information

## Contract Address
\`$ACCOUNT_ADDRESS\`

## Network
Testnet

## Deployed Modules
- \`$ACCOUNT_ADDRESS::movehub\` - Main MoveHub platform
- \`$ACCOUNT_ADDRESS::rewards\` - Rewards system
- \`$ACCOUNT_ADDRESS::analytics\` - Analytics system

## Frontend
- Built and ready for deployment
- Environment variables configured
- Contract address: \`$ACCOUNT_ADDRESS\`

## Next Steps
1. Deploy frontend to your preferred hosting platform (Vercel, Netlify, etc.)
2. Update frontend environment variables with production values
3. Test all functionality on testnet
4. Deploy to mainnet when ready

## Useful Commands
\`\`\`bash
# View account resources
aptos account list --query resources

# View platform stats
aptos move view --function-id $ACCOUNT_ADDRESS::movehub::get_platform_stats

# Create a test quest
aptos move run --function-id $ACCOUNT_ADDRESS::movehub::create_quest \\
  --args string:"Test Quest" \\
  string:"A test quest for demonstration" \\
  u8:1 \\
  u8:2 \\
  u64:100 \\
  null \\
  null \\
  vector:string:[] \\
  vector:string:["test","demo"]
\`\`\`

## Frontend Development
\`\`\`bash
cd frontend
npm run dev
\`\`\`

Deployment completed at: $(date)
EOF

print_success "Deployment summary created: DEPLOYMENT_INFO.md"

# Final success message
echo ""
print_success "🎉 MoveHub deployment completed successfully!"
echo ""
print_status "Contract Address: $ACCOUNT_ADDRESS"
print_status "Network: Testnet"
print_status "Frontend: Ready for deployment"
echo ""
print_status "To start the frontend development server:"
print_status "  cd frontend && npm run dev"
echo ""
print_status "To view deployment details, check DEPLOYMENT_INFO.md"
echo ""
print_success "Happy coding! 🚀"
