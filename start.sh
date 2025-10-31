#!/bin/bash

# Quick start script for Freqtrade
# Run this after initial setup to start trading

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if in freqtrade directory
if [ ! -f "freqtrade-env/bin/activate" ]; then
    print_error "Please run this script from the freqtrade directory"
    exit 1
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source freqtrade-env/bin/activate

# Check if config exists
if [ ! -f "user_data/config.json" ]; then
    print_warning "Config file not found. Creating basic config..."
    freqtrade new-config --config user_data/config.json
    print_warning "Please edit user_data/config.json with your Bybit API keys before proceeding!"
    exit 1
fi

# Menu for user choice
echo ""
echo "🚀 Freqtrade Quick Start Menu"
echo "================================"
echo "1. Download historical data"
echo "2. Run backtest"
echo "3. Start paper trading (dry run)"
echo "4. Start live trading (REAL MONEY)"
echo "5. Start FreqUI web interface"
echo "6. View logs"
echo "7. Exit"
echo ""

read -p "Choose an option (1-7): " choice

case $choice in
    1)
        print_status "Downloading historical data..."
        freqtrade download-data --exchange bybit --timeframes 5m 1h --days 30 --config user_data/config.json
        ;;
    2)
        print_status "Running backtest..."
        freqtrade backtesting --config user_data/config.json --strategy SimpleStrategy --timeframe 5m
        ;;
    3)
        print_warning "Starting paper trading (dry run)..."
        freqtrade trade --config user_data/config.json --strategy SimpleStrategy
        ;;
    4)
        print_error "⚠️  LIVE TRADING WITH REAL MONEY ⚠️"
        echo ""
        print_warning "Make sure you have:"
        echo "- Tested your strategy thoroughly with paper trading"
        echo "- Set conservative position sizes"
        echo "- Added your real API keys to config.json"
        echo "- Set dry_run to false in config.json"
        echo ""
        read -p "Are you absolutely sure you want to proceed? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            print_status "Starting live trading..."
            freqtrade trade --config user_data/config.json --strategy SimpleStrategy
        else
            print_status "Live trading cancelled. Good choice for safety!"
        fi
        ;;
    5)
        print_status "Starting FreqUI web interface..."
        print_status "Access at: http://localhost:8080"
        freqtrade webserver --config user_data/config.json
        ;;
    6)
        print_status "Viewing recent logs..."
        if [ -f "user_data/logs/freqtrade.log" ]; then
            tail -n 50 user_data/logs/freqtrade.log
        else
            print_warning "No log file found. Start trading first to generate logs."
        fi
        ;;
    7)
        print_status "Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid option. Please choose 1-7."
        ;;
esac