#!/bin/bash

# TA-Lib Installation Script
# This script provides multiple methods to install TA-Lib on Linux

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
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo "🔧 TA-Lib Installation Helper"
echo "=============================="

# Check if TA-Lib is already installed
check_talib() {
    python3 -c "import talib; print('TA-Lib version:', talib.__version__)" 2>/dev/null
    return $?
}

if check_talib; then
    print_status "TA-Lib is already installed!"
    exit 0
fi

print_warning "TA-Lib not found. Choose installation method:"
echo ""
echo "1. Install from source (recommended)"
echo "2. Install via pip with pre-compiled wheels"
echo "3. Install via conda (if you have conda)"
echo "4. Manual instructions"
echo "5. Exit"
echo ""

read -p "Choose an option (1-5): " choice

case $choice in
    1)
        print_status "Installing TA-Lib from source..."
        
        # Install build dependencies
        if command -v apt >/dev/null 2>&1; then
            sudo apt install -y build-essential curl
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y gcc gcc-c++ make curl
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm base-devel curl
        fi
        
        # Download and compile TA-Lib
        TALIB_VERSION="0.4.0"
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        print_status "Downloading TA-Lib source..."
        curl -L "http://prdownloads.sourceforge.net/ta-lib/ta-lib-${TALIB_VERSION}-src.tar.gz" -o ta-lib.tar.gz
        
        print_status "Extracting and compiling..."
        tar -xzf ta-lib.tar.gz
        cd "ta-lib/"
        
        ./configure --prefix=/usr/local
        make
        sudo make install
        
        # Update library path
        echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/ta-lib.conf >/dev/null
        sudo ldconfig
        
        cd "$OLDPWD"
        rm -rf "$TEMP_DIR"
        
        print_status "Installing Python TA-Lib wrapper..."
        pip3 install TA-Lib
        
        print_status "TA-Lib installation completed!"
        ;;
        
    2)
        print_status "Installing TA-Lib via pip..."
        pip3 install --upgrade pip
        pip3 install TA-Lib
        print_status "Installation completed!"
        ;;
        
    3)
        print_status "Installing TA-Lib via conda..."
        if ! command -v conda >/dev/null 2>&1; then
            print_error "Conda not found. Please install Miniconda or Anaconda first."
            exit 1
        fi
        conda install -c conda-forge ta-lib
        print_status "Installation completed!"
        ;;
        
    4)
        print_info "Manual Installation Instructions:"
        echo ""
        echo "Option A - Ubuntu/Debian:"
        echo "  sudo apt update"
        echo "  sudo apt install libta-lib-dev"
        echo "  pip3 install TA-Lib"
        echo ""
        echo "Option B - Fedora/CentOS/RHEL:"
        echo "  sudo dnf install ta-lib-devel"
        echo "  pip3 install TA-Lib"
        echo ""
        echo "Option C - From source:"
        echo "  wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz"
        echo "  tar -xzf ta-lib-0.4.0-src.tar.gz"
        echo "  cd ta-lib/"
        echo "  ./configure --prefix=/usr/local"
        echo "  make"
        echo "  sudo make install"
        echo "  echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/ta-lib.conf"
        echo "  sudo ldconfig"
        echo "  pip3 install TA-Lib"
        echo ""
        echo "Option D - Using conda:"
        echo "  conda install -c conda-forge ta-lib"
        ;;
        
    5)
        print_status "Goodbye!"
        exit 0
        ;;
        
    *)
        print_error "Invalid option. Please choose 1-5."
        exit 1
        ;;
esac

# Verify installation
echo ""
print_status "Verifying installation..."
if check_talib; then
    print_status "✅ TA-Lib installation successful!"
else
    print_error "❌ TA-Lib installation failed!"
    echo ""
    print_warning "Troubleshooting tips:"
    echo "1. Make sure you have build tools installed (gcc, make)"
    echo "2. Try running: sudo ldconfig"
    echo "3. Check if /usr/local/lib is in your library path"
    echo "4. For Python virtual environments, make sure TA-Lib is installed in the correct environment"
    exit 1
fi