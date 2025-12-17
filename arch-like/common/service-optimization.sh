#!/bin/bash

# System Service Optimization for Arch-like Systems
# Version: 1.1.0
# Last Updated: 2025-12-17
# Description: Optimizes system services for better performance, boot time, and reliability

# -----------------------------------------------------------------------------
# Changelog
# -----------------------------------------------------------------------------
# 1.1.0 (2025-12-17):
#   - Updated to use common function library
#   - Added improved error handling and logging
#   - Added standardized backup mechanism
#   - Improved user interaction
#   - Added script cleanup functionality
#   - Added version control and changelog
#
# 1.0.0 (2025-12-01):
#   - Initial version
#   - Basic service management and optimization
#   - Added earlyoom for better OOM management
#   - Added fstrim.timer for SSDs
#   - Added sysctl optimizations

# -----------------------------------------------------------------------------

# Source the common function library
SCRIPT_DIR="$(dirname "$0")"
COMMON_LIB="$SCRIPT_DIR/../../common/common-lib.sh"

if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    echo "Error: Common function library not found at $COMMON_LIB"
    exit 1
fi

# Script-specific variables
SCRIPT_VERSION="1.1.0"
SCRIPT_NAME="$(basename "$0")"

# -----------------------------------------------------------------------------

# Initialize script
init_script

# Show script header
show_header "System Service Optimization"

# -----------------------------------------------------------------------------
# Main script execution
# -----------------------------------------------------------------------------

# Show system boot time
log_info "Current system boot time:"
systemd-analyze
log_info ""

# Show top services by boot time
log_info "Top services by boot time:"
systemd-analyze blame | head -20
log_info ""

# Show failed services
log_info "Failed services:"
systemctl --failed
log_info ""

# List all enabled services
log_info "All enabled services:"
systemctl list-unit-files --state=enabled | head -30
log_info "(Only showing first 30 services)"
log_info ""

# Define list of services to consider disabling
log_info "Services that can be considered for disabling:"
echo "=================================================="
cat <<EOF
# Desktop environment services (if not needed)
- bluetooth.service
- cups.service
- avahi-daemon.service
- rtkit-daemon.service
- colord.service
- geoclue.service
- pulseaudio.service (if using pipewire)
- pipewire.service (if using pulseaudio)

# Network services (if not needed)
- NetworkManager.service (if using systemd-networkd)
- wpa_supplicant.service (if using wired network)

# Printing services (if not needed)
- cups-browsed.service
- cups.service

# Virtualization services (if not needed)
- libvirtd.service
- virtlockd.service
- virtlogd.service

# Container services (if not needed)
- docker.service
- containerd.service
- podman.service
- crio.service

# Storage services (if not needed)
- iscsid.service
- iscsiuio.service
- multipathd.service

# Remote access services (if not needed)
- sshd.service (only if you don't need remote access)
- telnet.service

# Monitoring services (if not needed)
- cockpit.service
- prometheus-node-exporter.service

# Audio services (if not needed)
- pipewire.service (if using pulseaudio)
- wireplumber.service (if not using pipewire)
EOF

echo ""

# Interactive service management
log_info "Interactive service management:"
echo "=================================================="
echo "Available options:"
echo "1. Disable a specific service"
echo "2. Enable a specific service"
echo "3. Show service status"
echo "4. List services by resource usage"
echo "5. Exit service management"
echo ""

while true; do
    read -p "Enter your choice (1-5): " service_choice
    echo ""
    
    case $service_choice in
        1)
            read -p "Enter service name to disable: " service_name
            log_info "Disabling $service_name..."
            disable_service "$service_name"
            log_info "$service_name has been disabled and stopped."
            echo ""
            ;;
        2)
            read -p "Enter service name to enable: " service_name
            log_info "Enabling $service_name..."
            enable_service "$service_name"
            log_info "$service_name has been enabled and started."
            echo ""
            ;;
        3)
            read -p "Enter service name to check status: " service_name
            log_info "Status of $service_name:"
            check_service "$service_name"
            echo ""
            ;;
        4)
            log_info "Top services by resource usage:"
            log_info "(Requires systemd-cgtop)"
            if command -v systemd-cgtop &> /dev/null; then
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            else
                log_info "Installing systemd-container package for systemd-cgtop..."
                install_packages systemd-container
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            fi
            echo ""
            ;;
        5)
            log_info "Exiting service management..."
            break
            ;;
        *)
            log_warn "Invalid choice. Please enter a number between 1-5."
            echo ""
            ;;
    esac
done

# Enable systemd-boot-update.service if using systemd-boot
log_info "Checking for systemd-boot..."
if [ -d "/boot/loader" ]; then
    log_info "systemd-boot detected. Enabling systemd-boot-update.service..."
    enable_service "systemd-boot-update.service"
    log_info "systemd-boot-update.service enabled."
else
    log_warn "systemd-boot not detected. Skipping systemd-boot-update.service."
fi
log_info ""

# Enable earlyoom for better OOM management
log_info "Enabling earlyoom..."
if ! command -v earlyoom &> /dev/null; then
    log_info "Installing earlyoom..."
    install_packages earlyoom
fi

enable_service "earlyoom"

# Configure earlyoom
log_info "Configuring earlyoom..."
create_file "/etc/default/earlyoom" "EARLYOOM_ARGS=\"-r 60 -n -p 10\""

restart_service "earlyoom"

log_info "earlyoom enabled and configured."
log_info ""

# Enable fstrim.timer for SSDs
log_info "Enabling fstrim.timer for SSDs..."
enable_service "fstrim.timer"

log_info "fstrim.timer enabled."
log_info ""

# Apply sysctl optimizations
log_info "Applying sysctl optimizations..."

# Create sysctl optimization file with backup
backup "/etc/sysctl.d/99-arch-optimizations.conf" "sysctl optimizations"

create_file "/etc/sysctl.d/99-arch-optimizations.conf" "# Arch Linux system optimizations

# Memory management
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.overcommit_memory=1

# Network optimization
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_syncookies=1

# File system optimization
fs.file-max=1048576"

# Apply sysctl changes
log_info "Applying sysctl changes..."
sudo sysctl --system
check_success $? "sysctl optimizations applied" "Failed to apply sysctl optimizations"

log_info "sysctl optimizations applied."
log_info ""

# Show final optimization summary
show_footer "true"

log_info "Key optimizations applied:"
echo "- System boot time analyzed"
echo "- Top services by boot time identified"
echo "- Failed services checked"
echo "- Interactive service management available"
echo "- systemd-boot-update.service enabled (if applicable)"
echo "- earlyoom enabled for better OOM management"
echo "- fstrim.timer enabled for SSDs"
echo "- sysctl optimizations applied"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to see the full effect of service changes"
echo "- Use 'systemctl list-dependencies' to check service dependencies"
echo "- Use 'systemctl mask' to completely disable unwanted services"
echo "- Regularly check 'systemctl --failed' for failed services"
echo "- Consider using 'systemctl-analyze critical-chain' for more boot analysis"

# -----------------------------------------------------------------------------
# End of script
# -----------------------------------------------------------------------------

