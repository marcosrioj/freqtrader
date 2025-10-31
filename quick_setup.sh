#!/bin/bash

# Quick Setup Script for existing freqtrade project
# Use this when you already have freqtrade source code

set -e

echo "🚀 Quick Freqtrade setup for existing project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Install TA-Lib first if not available
print_status "Checking TA-Lib installation..."
if ! python3 -c "import talib" >/dev/null 2>&1; then
    print_warning "TA-Lib not found. Installing..."
    ./install_talib.sh
else
    print_status "TA-Lib already installed"
fi

# Clone Freqtrade if we don't have the source
if [ ! -f "setup.py" ] && [ ! -f "pyproject.toml" ]; then
    print_status "Freqtrade source not found. Cloning repository..."
    
    # Create a temporary directory and clone there
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/freqtrade/freqtrade.git
    
    # Move contents to our project directory
    cd freqtrade
    cp -r * "$OLDPWD/"
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    
    print_status "Freqtrade source code copied to current directory"
else
    print_status "Freqtrade source found in current directory"
fi

# Create virtual environment
if [ ! -d "freqtrade-env" ]; then
    print_status "Creating virtual environment..."
    python3 -m venv freqtrade-env
else
    print_warning "Virtual environment already exists..."
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source freqtrade-env/bin/activate

# Install dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip

# Install Freqtrade
if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    print_status "Installing Freqtrade from source..."
    pip install -e .
    pip install freqtrade[plot,hyperopt]
else
    print_status "Installing Freqtrade from PyPI..."
    pip install freqtrade[plot,hyperopt]
fi

# Create user data directory structure
print_status "Creating user data directories..."
mkdir -p user_data/{strategies,logs,backtest_results,plot,notebooks}

# Create initial configuration if it doesn't exist
if [ ! -f "user_data/config.json" ]; then
    print_status "Creating initial configuration..."
    freqtrade new-config --config user_data/config.json
fi

# Verify installation
print_status "Verifying installation..."
freqtrade --version

print_status "✅ Quick setup completed successfully!"
print_warning "Next steps:"
echo "1. Edit user_data/config.json with your Bybit API keys"
echo "2. Test with paper trading first (dry_run: true)"
echo "3. Run: ./start.sh to begin trading"
echo ""
echo "To activate the environment in future sessions:"
echo "source freqtrade-env/bin/activate"