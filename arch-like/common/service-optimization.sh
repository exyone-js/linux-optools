#!/bin/bash

# System Service Optimization for Arch-like Systems

set -e

echo "Starting system service optimization..."

# 1. Show system boot time
echo "1. Current system boot time:"
 systemd-analyze
 echo ""

# 2. Show top services by boot time
echo "2. Top services by boot time:"
 systemd-analyze blame | head -20
 echo ""

# 3. Show failed services
echo "3. Failed services:"
 systemctl --failed
 echo ""

# 4. List all enabled services
echo "4. All enabled services:"
 systemctl list-unit-files --state=enabled | head -30
echo "(Only showing first 30 services)"
echo ""

# 5. Define list of services to consider disabling
echo "5. Services that can be considered for disabling:"
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

# 6. Interactive service management
echo "6. Interactive service management:"
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
            echo "Disabling $service_name..."
            sudo systemctl disable --now "$service_name"
            echo "$service_name has been disabled and stopped."
            echo ""
            ;;
        2)
            read -p "Enter service name to enable: " service_name
            echo "Enabling $service_name..."
            sudo systemctl enable --now "$service_name"
            echo "$service_name has been enabled and started."
            echo ""
            ;;
        3)
            read -p "Enter service name to check status: " service_name
            echo "Status of $service_name:"
            systemctl status "$service_name" --no-pager
            echo ""
            ;;
        4)
            echo "Top services by resource usage:"
            echo "(Requires systemd-cgtop)"
            if command -v systemd-cgtop &> /dev/null; then
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            else
                echo "Installing systemd-container package for systemd-cgtop..."
                sudo pacman -S --noconfirm systemd-container
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            fi
            echo ""
            ;;
        5)
            echo "Exiting service management..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1-5."
            echo ""
            ;;
    esac
done

# 7. Enable systemd-boot-update.service if using systemd-boot
echo "7. Checking for systemd-boot..."
if [ -d "/boot/loader" ]; then
    echo "systemd-boot detected. Enabling systemd-boot-update.service..."
    sudo systemctl enable --now systemd-boot-update.service
    echo "systemd-boot-update.service enabled."
else
    echo "systemd-boot not detected. Skipping systemd-boot-update.service."
fi
echo ""

# 8. Enable earlyoom for better OOM management
echo "8. Enabling earlyoom..."
if ! command -v earlyoom &> /dev/null; then
    echo "Installing earlyoom..."
    sudo pacman -S --noconfirm earlyoom
fi
sudo systemctl enable --now earlyoom

# Configure earlyoom
echo "Configuring earlyoom..."
sudo tee /etc/default/earlyoom <<EOF
EARLYOOM_ARGS="-r 60 -n -p 10"
EOF

sudo systemctl restart earlyoom

echo "earlyoom enabled and configured."
echo ""

# 9. Enable fstrim.timer for SSDs
echo "9. Enabling fstrim.timer for SSDs..."
sudo systemctl enable --now fstrim.timer

echo "fstrim.timer enabled."
echo ""

# 10. Apply sysctl optimizations
echo "10. Applying sysctl optimizations..."

# Check if sysctl.d directory exists
if [ ! -d "/etc/sysctl.d" ]; then
    sudo mkdir -p /etc/sysctl.d
fi

# Create sysctl optimization file
echo "Creating sysctl optimization file..."
sudo tee /etc/sysctl.d/99-arch-optimizations.conf <<EOF
# Arch Linux system optimizations

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
fs.file-max=1048576
EOF

# Apply sysctl changes
echo "Applying sysctl changes..."
sudo sysctl --system

echo "sysctl optimizations applied."
echo ""

# 11. Show final optimization summary
echo "11. System service optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
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
