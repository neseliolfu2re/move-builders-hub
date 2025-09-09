@echo off
REM MoveHub Deployment Script for Windows
REM This script deploys the MoveHub smart contracts and sets up the frontend

setlocal enabledelayedexpansion

echo 🚀 Starting MoveHub Deployment...

REM Check if aptos CLI is installed
aptos --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Aptos CLI is not installed. Please install it first.
    echo Visit: https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/
    exit /b 1
)

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed. Please install it first.
    exit /b 1
)

REM Check if npm is installed
npm --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm is not installed. Please install it first.
    exit /b 1
)

echo [INFO] All prerequisites are installed ✅

REM Set up Aptos account if not exists
echo [INFO] Setting up Aptos account...
aptos account list >nul 2>&1
if errorlevel 1 (
    echo [WARNING] No Aptos account found. Creating a new account...
    aptos init --network testnet
    if errorlevel 1 (
        echo [ERROR] Failed to create Aptos account
        exit /b 1
    )
    echo [SUCCESS] Aptos account created successfully
) else (
    echo [SUCCESS] Aptos account already exists
)

REM Get account address (simplified for Windows)
echo [INFO] Getting account address...
for /f "tokens=*" %%i in ('aptos account list --query account --output table ^| findstr "0x"') do (
    set ACCOUNT_ADDRESS=%%i
    goto :found_address
)
:found_address

REM Remove any extra characters and get just the address
for /f "tokens=1" %%a in ("!ACCOUNT_ADDRESS!") do set ACCOUNT_ADDRESS=%%a

echo [INFO] Using account: !ACCOUNT_ADDRESS!

REM Update Move.toml with the account address
echo [INFO] Updating Move.toml with account address...
powershell -Command "(Get-Content Move.toml) -replace 'movehub = \"0x1\"', 'movehub = \"!ACCOUNT_ADDRESS!\"' | Set-Content Move.toml"
echo [SUCCESS] Move.toml updated

REM Compile Move contracts
echo [INFO] Compiling Move contracts...
aptos move compile
if errorlevel 1 (
    echo [ERROR] Failed to compile Move contracts
    exit /b 1
)
echo [SUCCESS] Move contracts compiled successfully

REM Run tests
echo [INFO] Running Move tests...
aptos move test
if errorlevel 1 (
    echo [ERROR] Some tests failed
    exit /b 1
)
echo [SUCCESS] All tests passed ✅

REM Deploy contracts
echo [INFO] Deploying contracts to testnet...
aptos move publish --named-addresses movehub=!ACCOUNT_ADDRESS!
if errorlevel 1 (
    echo [ERROR] Failed to deploy contracts
    exit /b 1
)
echo [SUCCESS] Contracts deployed successfully to testnet

REM Initialize the platform
echo [INFO] Initializing MoveHub platform...
aptos move run --function-id !ACCOUNT_ADDRESS!::movehub::initialize
if errorlevel 1 (
    echo [ERROR] Failed to initialize platform
    exit /b 1
)
echo [SUCCESS] MoveHub platform initialized

REM Initialize rewards system
echo [INFO] Initializing rewards system...
aptos move run --function-id !ACCOUNT_ADDRESS!::rewards::initialize
if errorlevel 1 (
    echo [ERROR] Failed to initialize rewards system
    exit /b 1
)
echo [SUCCESS] Rewards system initialized

REM Initialize analytics system
echo [INFO] Initializing analytics system...
aptos move run --function-id !ACCOUNT_ADDRESS!::analytics::initialize
if errorlevel 1 (
    echo [ERROR] Failed to initialize analytics system
    exit /b 1
)
echo [SUCCESS] Analytics system initialized

REM Set up frontend
echo [INFO] Setting up frontend...
cd frontend

REM Install dependencies
echo [INFO] Installing frontend dependencies...
npm install
if errorlevel 1 (
    echo [ERROR] Failed to install frontend dependencies
    exit /b 1
)
echo [SUCCESS] Frontend dependencies installed

REM Update environment variables
echo [INFO] Updating environment variables...
(
echo NEXT_PUBLIC_APTOS_NETWORK=testnet
echo NEXT_PUBLIC_APTOS_NODE_URL=https://fullnode.testnet.aptoslabs.com
echo NEXT_PUBLIC_MOVEHUB_ADDRESS=!ACCOUNT_ADDRESS!
) > .env.local
echo [SUCCESS] Environment variables updated

REM Build frontend
echo [INFO] Building frontend...
npm run build
if errorlevel 1 (
    echo [ERROR] Failed to build frontend
    exit /b 1
)
echo [SUCCESS] Frontend built successfully

cd ..

REM Create deployment summary
echo [INFO] Creating deployment summary...
(
echo # MoveHub Deployment Information
echo.
echo ## Contract Address
echo `!ACCOUNT_ADDRESS!`
echo.
echo ## Network
echo Testnet
echo.
echo ## Deployed Modules
echo - `!ACCOUNT_ADDRESS!::movehub` - Main MoveHub platform
echo - `!ACCOUNT_ADDRESS!::rewards` - Rewards system
echo - `!ACCOUNT_ADDRESS!::analytics` - Analytics system
echo.
echo ## Frontend
echo - Built and ready for deployment
echo - Environment variables configured
echo - Contract address: `!ACCOUNT_ADDRESS!`
echo.
echo ## Next Steps
echo 1. Deploy frontend to your preferred hosting platform ^(Vercel, Netlify, etc.^)
echo 2. Update frontend environment variables with production values
echo 3. Test all functionality on testnet
echo 4. Deploy to mainnet when ready
echo.
echo ## Useful Commands
echo ```bash
echo # View account resources
echo aptos account list --query resources
echo.
echo # View platform stats
echo aptos move view --function-id !ACCOUNT_ADDRESS!::movehub::get_platform_stats
echo.
echo # Create a test quest
echo aptos move run --function-id !ACCOUNT_ADDRESS!::movehub::create_quest ^
echo   --args string:"Test Quest" ^
echo   string:"A test quest for demonstration" ^
echo   u8:1 ^
echo   u8:2 ^
echo   u64:100 ^
echo   null ^
echo   null ^
echo   vector:string:[] ^
echo   vector:string:["test","demo"]
echo ```
echo.
echo ## Frontend Development
echo ```bash
echo cd frontend
echo npm run dev
echo ```
echo.
echo Deployment completed at: %date% %time%
) > DEPLOYMENT_INFO.md

echo [SUCCESS] Deployment summary created: DEPLOYMENT_INFO.md

REM Final success message
echo.
echo [SUCCESS] 🎉 MoveHub deployment completed successfully!
echo.
echo [INFO] Contract Address: !ACCOUNT_ADDRESS!
echo [INFO] Network: Testnet
echo [INFO] Frontend: Ready for deployment
echo.
echo [INFO] To start the frontend development server:
echo [INFO]   cd frontend ^&^& npm run dev
echo.
echo [INFO] To view deployment details, check DEPLOYMENT_INFO.md
echo.
echo [SUCCESS] Happy coding! 🚀

pause
