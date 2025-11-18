#!/bin/bash

#############################################
# OpenWrt Build Script for Cudy WR3000-v1
#############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/openwrt_build"
OPENWRT_REPO="https://git.openwrt.org/openwrt/openwrt.git"
OPENWRT_DIR="${BUILD_DIR}/openwrt"
CONFIG_FILE="${SCRIPT_DIR}/wr3000.config"
FILES_DIR="${SCRIPT_DIR}/files"

#############################################
# Helper Functions
#############################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║   OpenWrt Build Script for Cudy WR3000-v1        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}[STEP]${NC} $1\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_disk_space() {
    local required_space=10485760  # 10GB in KB
    local available_space=$(df -k "${BUILD_DIR}" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    
    if [ "$available_space" -lt "$required_space" ]; then
        print_error "Insufficient disk space. Required: 10GB, Available: $(($available_space / 1024 / 1024))GB"
        return 1
    fi
    print_info "Disk space check passed: $(($available_space / 1024 / 1024))GB available"
    return 0
}

check_dependencies() {
    print_step "Checking system dependencies..."
    
    local missing_deps=()
    local deps=(git gcc g++ make gawk wget unzip python3 rsync)
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        print_info "Install them with:"
        echo ""
        if command -v apt &> /dev/null; then
            echo "  sudo apt update"
            echo "  sudo apt install build-essential clang flex bison g++ gawk \\"
            echo "    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \\"
            echo "    python3-setuptools rsync swig unzip zlib1g-dev file wget"
        elif command -v dnf &> /dev/null; then
            echo "  sudo dnf install @development-tools clang flex bison gawk gcc \\"
            echo "    gcc-c++ git ncurses-devel openssl-devel python3-setuptools \\"
            echo "    rsync swig unzip zlib-devel file wget"
        fi
        echo ""
        return 1
    fi
    
    print_success "All dependencies are installed"
    return 0
}

clone_openwrt() {
    print_step "Cloning OpenWrt source code..."
    
    if [ -d "${OPENWRT_DIR}" ]; then
        print_warning "OpenWrt directory already exists at ${OPENWRT_DIR}"
        read -p "Do you want to delete and re-clone? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing old OpenWrt directory..."
            rm -rf "${OPENWRT_DIR}"
        else
            print_info "Using existing OpenWrt directory"
            return 0
        fi
    fi
    
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    
    print_info "Cloning from ${OPENWRT_REPO}..."
    git clone "${OPENWRT_REPO}" openwrt
    
    cd "${OPENWRT_DIR}"
    print_success "OpenWrt source cloned successfully"
}

update_feeds() {
    print_step "Updating and installing feeds..."
    
    cd "${OPENWRT_DIR}"
    
    print_info "Updating feeds..."
    ./scripts/feeds update -a
    
    print_info "Installing feeds..."
    ./scripts/feeds install -a
    
    print_success "Feeds updated and installed"
}

copy_config() {
    print_step "Copying configuration and custom files..."
    
    cd "${OPENWRT_DIR}"
    
    if [ ! -f "${CONFIG_FILE}" ]; then
        print_error "Configuration file not found: ${CONFIG_FILE}"
        return 1
    fi
    
    print_info "Copying wr3000.config to .config..."
    cp "${CONFIG_FILE}" .config
    
    if [ -d "${FILES_DIR}" ]; then
        print_info "Copying custom files directory..."
        cp -r "${FILES_DIR}" ./
        print_success "Custom files copied successfully"
    else
        print_warning "Custom files directory not found: ${FILES_DIR}"
    fi
    
    print_success "Configuration copied successfully"
}

expand_config() {
    print_step "Expanding configuration..."
    
    cd "${OPENWRT_DIR}"
    
    print_info "Running make defconfig..."
    make defconfig
    
    print_success "Configuration expanded"
}

download_packages() {
    print_step "Downloading packages..."
    
    cd "${OPENWRT_DIR}"
    
    local cpu_cores=$(nproc)
    print_info "Downloading with ${cpu_cores} parallel jobs..."
    
    make download -j"${cpu_cores}" V=s
    
    print_success "All packages downloaded"
}

build_firmware() {
    print_step "Building firmware..."
    
    cd "${OPENWRT_DIR}"
    
    local cpu_cores=$(nproc)
    
    echo ""
    print_warning "This will take 1-3 hours depending on your system"
    echo ""
    echo "Build options:"
    echo "  1) Single-threaded build (slower but safer, recommended for first build)"
    echo "  2) Multi-threaded build (faster, uses ${cpu_cores} cores)"
    echo ""
    read -p "Choose build type (1 or 2): " -n 1 -r
    echo
    
    if [[ $REPLY == "1" ]]; then
        print_info "Starting single-threaded build with verbose output..."
        make -j1 V=s
    else
        print_info "Starting multi-threaded build with ${cpu_cores} cores..."
        make -j"${cpu_cores}"
    fi
    
    print_success "Firmware built successfully!"
}

show_results() {
    print_step "Build completed!"
    
    local firmware_dir="${OPENWRT_DIR}/bin/targets/mediatek/filogic"
    
    echo ""
    print_info "Firmware images location:"
    echo "  ${firmware_dir}"
    echo ""
    
    if [ -d "${firmware_dir}" ]; then
        print_info "Available firmware files:"
        ls -lh "${firmware_dir}"/*.bin 2>/dev/null || print_warning "No .bin files found"
        echo ""
        
        local sysupgrade=$(find "${firmware_dir}" -name "*sysupgrade.bin" 2>/dev/null | head -n1)
        local factory=$(find "${firmware_dir}" -name "*factory.bin" 2>/dev/null | head -n1)
        
        if [ -n "$sysupgrade" ]; then
            print_success "Sysupgrade image: $(basename $sysupgrade)"
        fi
        if [ -n "$factory" ]; then
            print_success "Factory image: $(basename $factory)"
        fi
    else
        print_error "Firmware directory not found!"
    fi
    
    echo ""
    print_info "Next steps:"
    echo "  - For initial installation from stock firmware, use the *-factory.bin file"
    echo "  - For upgrading existing OpenWrt, use the *-sysupgrade.bin file"
    echo ""
}

clean_build() {
    print_step "Cleaning build artifacts..."
    
    if [ -d "${OPENWRT_DIR}" ]; then
        cd "${OPENWRT_DIR}"
        
        echo "Clean options:"
        echo "  1) Clean (remove build artifacts, keep downloaded packages)"
        echo "  2) Dirclean (remove everything including downloaded packages)"
        echo "  3) Cancel"
        echo ""
        read -p "Choose option (1-3): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                make clean
                print_success "Build artifacts cleaned"
                ;;
            2)
                make dirclean
                print_success "Build directory completely cleaned"
                ;;
            *)
                print_info "Clean cancelled"
                ;;
        esac
    else
        print_warning "OpenWrt directory not found: ${OPENWRT_DIR}"
    fi
}

open_menuconfig() {
    print_step "Opening menuconfig..."
    
    if [ -d "${OPENWRT_DIR}" ]; then
        cd "${OPENWRT_DIR}"
        
        if [ ! -f ".config" ]; then
            print_warning ".config not found, copying from wr3000.config..."
            copy_config
            expand_config
        fi
        
        print_info "Starting menuconfig (use arrows to navigate, / to search, space to select)"
        make menuconfig
        
        print_info "Saving changes back to ${CONFIG_FILE}..."
        cp .config "${CONFIG_FILE}"
        print_success "Configuration saved"
    else
        print_error "OpenWrt directory not found: ${OPENWRT_DIR}"
    fi
}

#############################################
# Main Menu
#############################################

show_menu() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}         OpenWrt Build Menu${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo "  1) Full automated build (recommended)"
    echo "  2) Clone OpenWrt source"
    echo "  3) Update feeds"
    echo "  4) Copy config and files"
    echo "  5) Expand configuration"
    echo "  6) Download packages"
    echo "  7) Build firmware"
    echo "  8) Open menuconfig (customize build)"
    echo "  9) Clean build artifacts"
    echo "  10) Show build results"
    echo "  11) Check dependencies"
    echo "  0) Exit"
    echo ""
}

full_build() {
    print_banner
    print_info "Starting full automated build process..."
    
    check_dependencies || exit 1
    check_disk_space || exit 1
    
    clone_openwrt
    update_feeds
    copy_config
    expand_config
    download_packages
    build_firmware
    show_results
}

main() {
    print_banner
    
    while true; do
        show_menu
        read -p "Select option: " choice
        
        case $choice in
            1)
                full_build
                ;;
            2)
                check_dependencies || continue
                clone_openwrt
                ;;
            3)
                update_feeds
                ;;
            4)
                copy_config
                ;;
            5)
                expand_config
                ;;
            6)
                download_packages
                ;;
            7)
                build_firmware
                show_results
                ;;
            8)
                open_menuconfig
                ;;
            9)
                clean_build
                ;;
            10)
                show_results
                ;;
            11)
                check_dependencies
                check_disk_space
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option: $choice"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main menu
main
