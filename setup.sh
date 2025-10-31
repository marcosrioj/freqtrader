#!/bin/bash

# Freqtrade Setup Script for Ubuntu/Debian
# This script automates the initial setup process

set -e

echo "🚀 Starting Freqtrade setup..."

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

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
print_status "Installing Python and dependencies..."
sudo apt install -y python3 python3-pip python3-venv git curl wget

# Install TA-Lib
print_status "Installing TA-Lib..."
sudo apt install -y libta-lib-dev build-essential

# Check if freqtrade directory exists
if [ ! -d "freqtrade" ]; then
    print_status "Cloning Freqtrade repository..."
    git clone https://github.com/freqtrade/freqtrade.git
else
    print_warning "Freqtrade directory already exists, skipping clone..."
fi

cd freqtrade

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

# Install Freqtrade
print_status "Installing Freqtrade..."
pip install --upgrade pip
pip install -e .
pip install freqtrade[plot,hyperopt]

# Create user data directory structure
print_status "Creating user data directories..."
mkdir -p user_data/{strategies,logs,backtest_results,plot,notebooks}

# Verify installation
print_status "Verifying installation..."
freqtrade --version

print_status "✅ Freqtrade setup completed successfully!"
print_warning "Next steps:"
echo "1. Configure your Bybit API keys in user_data/config.json"
echo "2. Test with paper trading first"
echo "3. Only use real money after thorough testing"
echo ""
echo "To activate the environment in future sessions:"
echo "cd freqtrade && source freqtrade-env/bin/activate"