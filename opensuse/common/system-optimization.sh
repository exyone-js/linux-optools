#!/bin/bash

# System Optimization for openSUSE

set -e

echo "Starting openSUSE system optimization..."

# 1. Show system information
echo "1. System information:"
 cat /etc/os-release
 echo ""

# 2. Show boot time
echo "2. Current system boot time:"
 systemd-analyze
 echo ""

# 3. Show top services by boot time
echo "3. Top services by boot time:"
 systemd-analyze blame | head -20
 echo ""

# 4. Show failed services
echo "4. Failed services:"
 systemctl --failed
 echo ""

# 5. Service optimization
echo "5. Service optimization..."

# Disable unnecessary services
unnecessary_services=("bluetooth" "cups" "avahi-daemon" "chronyd" "postfix" "wpa_supplicant" "firewalld" "NetworkManager")

for service in "${unnecessary_services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Disabling $service..."
        sudo systemctl disable --now "$service"
    fi
done

# Enable essential services
essential_services=("sshd" "crond" "systemd-journald" "systemd-networkd" "systemd-resolved")

for service in "${essential_services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Enabling $service..."
        sudo systemctl enable --now "$service"
    fi
done

echo "Service optimization completed."
echo ""

# 6. Apply sysctl optimizations
echo "6. Applying sysctl optimizations..."

# Create sysctl optimization file
sudo tee /etc/sysctl.d/99-opensuse-optimizations.conf <<EOF
# openSUSE system optimizations

# Memory management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
vm.overcommit_ratio = 90

# Network optimization
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_syn_backlog = 4096

# Security
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# File system
fs.file-max = 1048576
EOF

# Apply sysctl changes
sudo sysctl --system
echo "sysctl optimizations applied."
echo ""

# 7. Disk I/O optimization
echo "7. Disk I/O optimization..."

# Show current disk I/O schedulers
echo "Current disk I/O schedulers:"
for disk in $(lsblk -nd -o NAME | grep -E 'sd|nvme'); do
    echo "$disk: $(cat /sys/block/$disk/queue/scheduler)"
done

# Set scheduler to mq-deadline for all disks
for disk in $(lsblk -nd -o NAME | grep -E 'sd|nvme'); do
    echo "Setting mq-deadline scheduler for $disk..."
    echo mq-deadline | sudo tee /sys/block/$disk/queue/scheduler
    # Make it persistent
    echo "ACTION==\"add|change\", KERNEL==\"$disk\", ATTR{queue/scheduler}==\"*\", ATTR{queue/scheduler}="mq-deadline"" | sudo tee -a /etc/udev/rules.d/60-disk-scheduler.rules
done

echo "Disk I/O optimization completed."
echo ""

# 8. Enable fstrim.timer for SSDs
echo "8. Enabling fstrim.timer for SSDs..."
sudo systemctl enable --now fstrim.timer
echo "fstrim.timer enabled."
echo ""

# 9. Enable earlyoom for better OOM management
echo "9. Enabling earlyoom..."
if ! command -v earlyoom &> /dev/null; then
    echo "Installing earlyoom..."
    sudo zypper install -y earlyoom
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

# 10. Security hardening
echo "10. Security hardening..."

# Install security packages
sudo zypper install -y fail2ban openscap-scanner scap-security-guide

# Enable fail2ban
echo "Enabling fail2ban..."
sudo systemctl enable --now fail2ban

# Configure fail2ban for SSH
sudo tee /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
maxretry = 3
findtime = 86400
bantime = 86400
EOF

sudo systemctl restart fail2ban

echo "Security hardening completed."
echo ""

# 11. Install system monitoring tools
echo "11. Installing system monitoring tools..."
sudo zypper install -y htop iotop bashtop btop nmon conky
echo "System monitoring tools installed."
echo ""

# 12. Cleanup unnecessary packages
echo "12. Cleaning up unnecessary packages..."
sudo zypper remove --clean-deps -y $(zypper packages --unneeded -i | awk 'NR>2 {print $3}') 2>/dev/null || true
sudo zypper clean -a
echo "Cleanup completed."
echo ""

# 13. Show final optimization summary
echo "13. openSUSE system optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System information and boot time analyzed"
echo "- Service optimization (unnecessary services disabled, essential services enabled)"
echo "- sysctl optimizations applied"
echo "- Disk I/O scheduler set to mq-deadline"
echo "- fstrim.timer enabled for SSDs"
echo "- earlyoom enabled for better OOM management"
echo "- Security hardening with fail2ban"
echo "- System monitoring tools installed"
echo "- System cleaned up"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to apply all changes"
echo "- Use 'systemctl list-dependencies' to check service dependencies"
echo "- Use 'systemctl mask' to completely disable unwanted services"
echo "- Regularly check 'systemctl --failed' for failed services"
echo "- Run 'sudo zypper update' to keep your system updated"