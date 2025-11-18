# Custom OpenWrt Firmware Builder

This repository provides automated build scripts and configuration for creating custom OpenWrt firmware images for routers.

## 🎯 Supported Device

- **Cudy WR3000-v1** - Configuration: `wr3000.config`

## 🚀 Quick Start

### 1. Setup Build Environment
```bash
chmod +x setup.sh
./setup.sh
```

This automatically installs all required dependencies for your Linux distribution.

### 2. Build Firmware
```bash
chmod +x build_openwrt.sh
./build_openwrt.sh
```

Select **option 1** for fully automated build, or use individual menu options for step-by-step control.

## 📦 What's Included

### Features
- **WiFi UCODE scripts** (faster boot)
- **WireGuard VPN** with full configuration support
- **Policy Based Routing** (PBR) - Route specific traffic through VPN
- **AdBlock Fast** - DNS-level ad and malware blocking
- **CAKE QoS** - Advanced traffic shaping for [cake-wg-pbr](https://github.com/lynxthecat/cake-wg-pbr)
- **LuCI Web Interface** with HTTPS support

### Security Hardening
- OpenSSH server (replaces Dropbear)
- Strong SSH algorithms and key exchange methods
- OpenSSL with modern ciphers only
- Stack protection (STACKPROTECTOR_STRONG)
- ASLR with PIE for all packages
- FORTIFY_SOURCE_2

### Optimizations
- Cortex-A53 CPU optimizations (cortex-a53+crc+crypto)
- Link-Time Optimization (LTO)
- BBR TCP congestion control
- Disabled debugging features for smaller image

### Custom Files
- SSH hardening configuration: [`ssh_hardening.conf`](files/etc/ssh/sshd_config.d/ssh_hardening.conf)
- Custom SSH daemon config: [`sshd_config`](files/etc/ssh/sshd_config)
- Quality-of-life UCI defaults: [`999-QOL_config`](files/etc/uci-defaults/999-QOL_config)
- Automated upgrade script: [`upgrade_custom_openwrt`](files/usr/bin/upgrade_custom_openwrt)

### Removed Packages
- odhcp, upnp, iptables (uses nftables)
- avahi, samba, USB storage support
- Debugging and kernel development features

Check `wr3000.config` for complete details.

## 🛠️ Build Scripts

### `setup.sh`
Automated dependency installer that detects your Linux distribution:
- Ubuntu/Debian
- Fedora/RHEL/CentOS
- Arch/Manjaro
- openSUSE

### `build_openwrt.sh`
Interactive build script with menu:
1. **Full automated build** - Complete one-click process
2. Clone OpenWrt source
3. Update feeds
4. Copy config and files
5. Expand configuration
6. Download packages
7. Build firmware
8. Open menuconfig (customize)
9. Clean build artifacts
10. Show build results
11. Check dependencies

## 📋 Build Process

The automated build will:
1. ✅ Check system dependencies and disk space (10GB+ required)
2. ✅ Clone OpenWrt source code
3. ✅ Update and install feeds
4. ✅ Copy custom configuration and files
5. ✅ Download required packages
6. ✅ Compile firmware (1-3 hours depending on system)
7. ✅ Display firmware location

## 📍 Output Location

Firmware images will be in:
```
~/openwrt_build/openwrt/bin/targets/mediatek/filogic/
```

Files:
- `*-sysupgrade.bin` - For upgrading existing OpenWrt
- `*-factory.bin` - For initial installation from stock firmware

## 🎨 Customization

### Modify Build Configuration
```bash
./build_openwrt.sh
# Select option 8: Open menuconfig
```

Changes are automatically saved back to the config file.

### Add Custom Files
Place files in `files/` directory matching router filesystem structure:
```
files/
├── etc/
│   └── config/
└── usr/
    └── bin/
```

## 📖 Detailed Documentation

See [`BUILD_INSTRUCTIONS.md`](BUILD_INSTRUCTIONS.md) for comprehensive build guide.

## 🤖 GitHub Actions Automation

Automated CI builds live in `.github/workflows/build-openwrt.yaml` and build the WR3000 target.

### Triggers
- `workflow_dispatch` (manual) with optional upstream override
- `push` to `main` when configs, overlays, or workflow change
- Nightly cron (`38 1 * * *`)

### Runners
- **Cudy WR3000:** Self-hosted runner with labels `self-hosted`, `linux`, `x64`, `debian`

Ensure the self-runner has the OpenWrt build dependencies installed (`git`, `gcc/g++`, `make`, `flex`, `bison`, `gawk`, `rsync`, `python3`, `wget`, `unzip`, `swig`, `clang/llvm`, `libncurses-dev`, `libssl-dev`, `zlib1g-dev`).

### What the workflow does
1. Clones the upstream OpenWrt repository/branch (defaults to `openwrt/openwrt@main`)
2. Restores cached `dl/` downloads
3. Applies this repo's `files/` overlay and config
4. Runs `make download` + `make` with automatic serial fallback
5. Uploads artifacts (sysupgrade/factory images, buildinfo, `.config`, and SHA256 sums)
6. Creates releases when triggered manually or via the schedule

### Manual Dispatch Helper
When starting a manual run, you can optionally set `remote_ref` to test a custom upstream revision.

## About upgrade_custom_openwrt script

I added a script to make upgrading OpenWRT super easy. Just run from a SSH terminal:
- `upgrade_custom_openwrt --now` to check if a newer firmware is available and upgrade if so.
- `upgrade_custom_openwrt --wait` to wait for clients activity to stop before upgrading.
- `upgrade_custom_openwrt --check` to check for new versions but not upgrade the router.

**IT IS NOT RECOMMENDED** to schedule the script to be executed automatically, although the script is very careful and checks sha256sums before trying to upgrade. Don't blame me if something goes wrong with scripts that **YOU** run in your router!

Notes:
- if you fork this repository, the script will be adapted to look for upgrades in your repository.
- The text output of upgrade_custom_openwrt script will show both in terminal and system logs.



## About SSH Hardening

To enhance the security of SSH connections, this firmware includes a hardened SSH configuration. The configuration is derived from recommendations by [SSH-Audit](https://github.com/jtesta/ssh-audit) and the [BSI](https://www.bsi.bund.de/), it specifies strong key exchange algorithms, ciphers, message authentication codes (MACs), host key algorithms, and public key algorithms. This ensures that only secure and up-to-date algorithms are used for SSH communication.



## Contributing

Contributions to this project are welcome. If you encounter any issues or have suggestions for improvements, please open an issue or submit a pull request on the GitHub repository.



## Acknowledgements

- The OpenWrt project for providing the foundation for this firmware build and support of [GL.iNet GL-MT6000](https://openwrt.org/toh/gl.inet/gl-mt6000) router.
- The community over at the [OpenWrt forum](https://forum.openwrt.org/t/mt6000-custom-build-with-luci-and-some-optimization-kernel-6-12-x/185241) for their valuable contributions and resources. 
- [pesa1234](https://github.com/pesa1234) for his [MT6000 custom builds](https://github.com/pesa1234/MT6000_cust_build).
- [Julius Bairaktaris](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder) from whom I "borrowed" much of this project (his repository is about custom builds for Xiaomi AX3600).
