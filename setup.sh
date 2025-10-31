#!/bin/bash

# Freqtrade Setup Script for Linux distributions
# This script automates the initial setup process

set -e

echo "🚀 Starting Freqtrade setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VERSION=$(lsb_release -sr)
    else
        DISTRO="unknown"
    fi
    print_info "Detected distribution: $DISTRO $VERSION"
}

# Install system dependencies based on distribution
install_system_deps() {
    detect_distro
    
    case $DISTRO in
        ubuntu|debian|pop|mint)
            print_status "Installing system packages for Ubuntu/Debian..."
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y python3 python3-pip python3-venv git curl wget build-essential
            ;;
        fedora|rhel|centos)
            print_status "Installing system packages for Fedora/RHEL/CentOS..."
            sudo dnf update -y
            sudo dnf install -y python3 python3-pip python3-venv git curl wget gcc gcc-c++ make
            ;;
        arch|manjaro)
            print_status "Installing system packages for Arch/Manjaro..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm python python-pip git curl wget base-devel
            ;;
        opensuse*)
            print_status "Installing system packages for openSUSE..."
            sudo zypper refresh
            sudo zypper install -y python3 python3-pip python3-venv git curl wget gcc gcc-c++ make
            ;;
        *)
            print_warning "Unknown distribution. Attempting generic installation..."
            if command -v apt >/dev/null 2>&1; then
                sudo apt update && sudo apt install -y python3 python3-pip python3-venv git curl wget build-essential
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3 python3-pip python3-venv git curl wget gcc gcc-c++ make
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm python python-pip git curl wget base-devel
            else
                print_error "Could not determine package manager. Please install manually:"
                echo "  - Python 3.8+"
                echo "  - pip"
                echo "  - git"
                echo "  - build tools (gcc, make)"
                exit 1
            fi
            ;;
    esac
}

# Install TA-Lib with multiple fallback methods
install_talib() {
    print_status "Installing TA-Lib..."
    
    # Method 1: Try package manager first
    case $DISTRO in
        ubuntu|debian|pop|mint)
            if sudo apt install -y libta-lib-dev; then
                print_status "TA-Lib installed via apt package manager"
                return 0
            fi
            ;;
        fedora|rhel|centos)
            if sudo dnf install -y ta-lib-devel; then
                print_status "TA-Lib installed via dnf package manager"
                return 0
            fi
            ;;
        arch|manjaro)
            if sudo pacman -S --noconfirm ta-lib; then
                print_status "TA-Lib installed via pacman"
                return 0
            fi
            ;;
    esac
    
    # Method 2: Install from source
    print_warning "Package manager installation failed. Installing TA-Lib from source..."
    
    TALIB_VERSION="0.4.0"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    print_status "Downloading TA-Lib source..."
    curl -L "http://prdownloads.sourceforge.net/ta-lib/ta-lib-${TALIB_VERSION}-src.tar.gz" -o ta-lib.tar.gz
    
    print_status "Extracting and compiling TA-Lib..."
    tar -xzf ta-lib.tar.gz
    cd "ta-lib/"
    
    ./configure --prefix=/usr/local
    make
    sudo make install
    
    # Update library path
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/ta-lib.conf
    sudo ldconfig
    
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    
    print_status "TA-Lib installed from source"
}

# Main installation
print_status "Starting system dependency installation..."
install_system_deps
install_talib

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