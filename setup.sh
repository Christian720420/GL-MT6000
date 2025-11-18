#!/bin/bash

#############################################
# Quick Setup Script for OpenWrt Build
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   OpenWrt Build Environment Setup                ║"
echo "║   Cudy WR3000-v1                                  ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Detected OS: $PRETTY_NAME\n"

# Install dependencies based on OS
install_deps() {
    case $OS in
        ubuntu|debian|linuxmint|pop)
            echo -e "${BLUE}[STEP]${NC} Installing dependencies for Debian/Ubuntu...\n"
            sudo apt update
            sudo apt install -y \
                build-essential clang flex bison g++ gawk \
                gcc-multilib g++-multilib gettext git \
                libncurses5-dev libssl-dev python3-setuptools \
                rsync swig unzip zlib1g-dev file wget \
                python3-distutils python3-dev libffi-dev
            ;;
        fedora|rhel|centos|rocky|almalinux)
            echo -e "${BLUE}[STEP]${NC} Installing dependencies for Fedora/RHEL...\n"
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y \
                clang flex bison gawk gcc gcc-c++ git \
                ncurses-devel openssl-devel python3-setuptools \
                rsync swig unzip zlib-devel file wget \
                python3-devel libffi-devel perl-FindBin \
                perl-File-Compare perl-File-Copy perl-Thread-Queue
            ;;
        arch|manjaro)
            echo -e "${BLUE}[STEP]${NC} Installing dependencies for Arch Linux...\n"
            sudo pacman -Syu --needed --noconfirm \
                base-devel clang flex bison gawk gcc git \
                ncurses openssl python-setuptools rsync swig \
                unzip zlib file wget python
            ;;
        opensuse*|sles)
            echo -e "${BLUE}[STEP]${NC} Installing dependencies for openSUSE...\n"
            sudo zypper install -y -t pattern devel_basis
            sudo zypper install -y \
                clang flex bison gawk gcc gcc-c++ git \
                ncurses-devel libopenssl-devel python3-setuptools \
                rsync swig unzip zlib-devel file wget
            ;;
        *)
            echo -e "${YELLOW}[WARN]${NC} Unsupported OS: $OS"
            echo -e "${YELLOW}[WARN]${NC} Please install build dependencies manually"
            echo ""
            echo "Required packages:"
            echo "  - build-essential/base-devel"
            echo "  - git, gcc, g++, make, gawk"
            echo "  - libncurses-dev, libssl-dev, zlib-dev"
            echo "  - python3, rsync, wget, unzip"
            echo ""
            read -p "Press Enter to continue anyway..."
            return 1
            ;;
    esac
    
    echo -e "\n${GREEN}[SUCCESS]${NC} Dependencies installed successfully!\n"
}

# Check if already installed
check_installed() {
    local missing=0
    local deps=(git gcc g++ make gawk wget unzip python3 rsync)
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing=$((missing + 1))
        fi
    done
    
    return $missing
}

# Main
echo -e "${BLUE}[INFO]${NC} Checking for existing dependencies...\n"

if check_installed; then
    echo -e "${GREEN}[SUCCESS]${NC} All basic dependencies are already installed!\n"
    read -p "Do you want to reinstall/update them anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[INFO]${NC} Skipping dependency installation"
        exit 0
    fi
fi

echo ""
read -p "Install build dependencies now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    install_deps
else
    echo -e "${YELLOW}[WARN]${NC} Skipping dependency installation"
    echo -e "${YELLOW}[WARN]${NC} Make sure all required packages are installed before building"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Setup Complete!                                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}[INFO]${NC} Next steps:"
echo "  1. Run: ./build_openwrt.sh"
echo "  2. Select option 1 for full automated build"
echo "  3. Wait 1-3 hours for compilation"
echo "  4. Flash the firmware to your router"
echo ""
