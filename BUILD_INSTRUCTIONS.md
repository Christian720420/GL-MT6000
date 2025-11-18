# Building OpenWrt for Cudy WR3000

This guide explains how to build a custom OpenWrt image for the Cudy WR3000-v1 router using the configuration and files in this repository.

## Prerequisites

### System Requirements
- Linux-based system (Ubuntu 20.04/22.04, Debian, or similar)
- At least 10GB of free disk space
- 4GB+ RAM recommended

### Required Packages

For **Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install build-essential clang flex bison g++ gawk \
gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
python3-setuptools rsync swig unzip zlib1g-dev file wget
```

For **Fedora**:
```bash
sudo dnf install @development-tools clang flex bison gawk gcc \
gcc-c++ git ncurses-devel openssl-devel python3-setuptools \
rsync swig unzip zlib-devel file wget
```

## Build Steps

### 1. Clone OpenWrt Source
```bash
cd ~
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
```

### 2. Update and Install Feeds
```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### 3. Copy Configuration File
Copy the `wr3000.config` from this repository to the OpenWrt source directory:
```bash
cp /path/to/GL-MT6000/wr3000.config .config
```

### 4. Copy Custom Files
Copy the custom files that will be included in the firmware image:
```bash
cp -r /path/to/GL-MT6000/files ./
```

This will include:
- SSH hardening configuration (`/etc/ssh/sshd_config.d/ssh_hardening.conf`)
- Custom SSH daemon config (`/etc/ssh/sshd_config`)
- Startup script (`/etc/rc.local`)
- QOL configuration script (`/etc/uci-defaults/999-QOL_config`)
- Custom upgrade script (`/usr/bin/upgrade_custom_openwrt`)

### 5. Expand Configuration (Optional)
If you want to review or modify the configuration in menuconfig:
```bash
make menuconfig
```

Otherwise, expand the diffconfig to full config:
```bash
make defconfig
```

### 6. Download Required Packages
```bash
make download -j$(nproc) V=s
```

### 7. Build the Firmware
**Single-threaded build (for first build or troubleshooting):**
```bash
make -j1 V=s
```

**Multi-threaded build (faster, once you know it works):**
```bash
make -j$(nproc)
```

The build process will take 1-3 hours depending on your system.

### 8. Locate the Firmware
After successful compilation, the firmware images will be in:
```
bin/targets/mediatek/filogic/
```

Look for files named:
- `openwrt-mediatek-filogic-cudy_wr3000-v1-squashfs-sysupgrade.bin` (for upgrading)
- `openwrt-mediatek-filogic-cudy_wr3000-v1-squashfs-factory.bin` (for initial installation)

## Key Features in This Build

### Security Enhancements
- OpenSSH server (instead of Dropbear)
- SSH hardening configuration
- OpenSSL (instead of mbedtls)
- Strong stack protection and ASLR
- FORTIFY_SOURCE_2 enabled

### Network Features
- Policy Based Routing (PBR)
- WireGuard VPN
- AdBlock Fast
- dnsmasq-full with DNSSEC
- CAKE traffic shaping support

### Web Interface
- LuCI web interface
- SSL/HTTPS support
- Advanced package manager

### Performance Optimizations
- Cortex-A53 CPU optimizations
- Link-Time Optimization (LTO)
- BBR TCP congestion control

## Flashing the Firmware

### Initial Installation (from stock firmware)
Use the `*-factory.bin` file through the stock firmware's web interface.

### Upgrading OpenWrt
Use the `*-sysupgrade.bin` file:
```bash
sysupgrade -v openwrt-mediatek-filogic-cudy_wr3000-v1-squashfs-sysupgrade.bin
```

Or use the custom upgrade script included in this build (once installed):
```bash
upgrade_custom_openwrt
```

## Troubleshooting

### Build Fails
- Clean the build directory: `make clean` or `make dirclean`
- Rebuild with single thread and verbose output: `make -j1 V=s`
- Check the logs in `logs/` directory

### Missing Dependencies
- Re-run `./scripts/feeds update -a && ./scripts/feeds install -a`
- Verify all system packages are installed

### Out of Space
- Ensure you have at least 10GB free
- Clean old builds: `make clean`

## Additional Resources

- [OpenWrt Build System Documentation](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem)
- [Cudy WR3000 Device Page](https://openwrt.org/toh/cudy/wr3000_v1)

## Custom Repository

This configuration uses the package repository hosted in this project:
```
https://raw.githubusercontent.com/Christian720420/GL-MT6000/main
```

## Notes

- First build will take longer as it downloads all dependencies
- Subsequent builds will be faster
- Keep your build environment updated for security patches
- The `files/` directory structure mirrors the root filesystem of the router
