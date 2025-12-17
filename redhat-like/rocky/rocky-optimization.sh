#!/bin/bash

# Rocky Linux Specific Optimization Script

set -e

echo "Starting Rocky Linux specific optimization..."

# 1. Show Rocky Linux version
echo "1. Rocky Linux version:"
 cat /etc/rocky-release
 echo ""

# 2. Update system to latest packages
echo "2. Updating system to latest packages..."
sudo dnf update -y
 echo ""

# 3. Enable necessary repositories
echo "3. Enabling necessary repositories..."

# Enable EPEL
sudo dnf install -y epel-release

# Enable PowerTools/CRB (CodeReady Builder)
sudo dnf config-manager --set-enabled crb

# Enable Rocky Linux extras
sudo dnf config-manager --set-enabled extras

 echo "Repositories enabled."
 echo ""

# 4. Service optimization
echo "4. Optimizing services..."

# Disable unnecessary services
unnecessary_services=("bluetooth" "cups" "avahi-daemon" "firewalld" "postfix" "chronyd")

for service in "${unnecessary_services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Disabling $service..."
        sudo systemctl disable --now "$service"
    fi
done

# Enable essential services
essential_services=("sshd" "crond" "rsyslog" "NetworkManager")

for service in "${essential_services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Enabling $service..."
        sudo systemctl enable --now "$service"
    fi
done

echo "Services optimized."
echo ""

# 5. Security hardening
echo "5. Security hardening..."

# Install security packages
sudo dnf install -y fail2ban openscap-scanner scap-security-guide audit

# Enable and configure fail2ban
sudo systemctl enable --now fail2ban

# Configure fail2ban for SSH
sudo tee /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
maxretry = 3
findtime = 86400
bantime = 86400
EOF

# Enable and configure auditd
sudo systemctl enable --now auditd

# Configure audit rules for important logs
sudo tee -a /etc/audit/rules.d/audit.rules <<EOF
-w /var/log/auth.log -p wa -k auth
-w /var/log/secure -p wa -k auth
-w /etc/passwd -p wa -k passwd
-w /etc/shadow -p wa -k shadow
-w /etc/group -p wa -k group
-w /etc/sudoers -p wa -k sudoers
EOF

sudo systemctl restart auditd

echo "Security hardening completed."
echo ""

# 6. Performance optimization
echo "6. Performance optimization..."

# Install performance tools
sudo dnf install -y tuned kernel-tools

# Enable and configure tuned
sudo systemctl enable --now tuned

# Set appropriate tuned profile
server_type=""
read -p "Is this a server or desktop? (server/desktop): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    server_type="server"
    echo "Setting tuned profile to throughput-performance..."
    sudo tuned-adm profile throughput-performance
else
    server_type="desktop"
    echo "Setting tuned profile to balanced..."
    sudo tuned-adm profile balanced
fi

# Optimize sysctl settings
echo "Optimizing sysctl settings..."
sudo tee -a /etc/sysctl.conf <<EOF

# Rocky Linux optimization
# Increase file descriptor limits
fs.file-max = 1048576

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
et.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF

# Apply sysctl changes
sudo sysctl -p

echo "Performance optimization completed."
echo ""

# 7. Storage and filesystem optimization
echo "7. Optimizing storage and filesystem..."

# Show current disk layout
echo "Current disk layout:"
 lsblk
 echo ""

# Enable TRIM for SSDs
echo "Enabling TRIM for SSDs..."
sudo systemctl enable --now fstrim.timer

echo "Storage optimization completed."
echo ""

# 8. Install monitoring and management tools
echo "8. Installing monitoring and management tools..."

if [[ "$server_type" == "server" ]]; then
    echo "Installing server monitoring tools..."
    sudo dnf install -y htop iotop nmon net-tools wget curl vim git
    
    # Install Prometheus node exporter (optional)
    read -p "Do you want to install Prometheus Node Exporter? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo dnf install -y prometheus-node-exporter
        sudo systemctl enable --now prometheus-node-exporter
        echo "Prometheus Node Exporter installed and enabled on port 9100."
    fi
else
    echo "Installing desktop utilities..."
    sudo dnf install -y htop iotop gnome-tweaks gnome-extensions-app
dnf-plugins-core
iwlwifi* firmware*
fi

echo "Monitoring tools installed."
echo ""

# 9. Kernel and boot optimization
echo "9. Optimizing kernel and boot..."

# Install latest kernel if available
echo "Checking for latest kernel..."
sudo dnf install -y kernel kernel-core kernel-modules

# Enable and configure earlyoom for better OOM management
echo "Enabling earlyoom..."
sudo dnf install -y earlyoom
sudo systemctl enable --now earlyoom

# Configure earlyoom
sudo tee /etc/default/earlyoom <<EOF
EARLYOOM_ARGS="-r 60 -n -p 10"
EOF

sudo systemctl restart earlyoom

echo "Kernel and boot optimization completed."
echo ""

# 10. Clean up unnecessary packages
echo "10. Cleaning up unnecessary packages..."
sudo dnf autoremove -y
sudo dnf clean all

# 11. Show final optimization summary
echo "11. Rocky Linux optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- EPEL and CRB repositories enabled"
echo "- Services optimized for $server_type"
echo "- Security hardening with fail2ban and auditd"
echo "- Performance tuned with appropriate profile"
echo "- sysctl settings optimized"
echo "- Storage optimization with TRIM enabled"
echo "- Monitoring tools installed"
echo "- Kernel updated and earlyoom configured"
echo "- System cleaned up"
echo ""
echo "Reboot your system to apply all changes completely."
echo "For further optimization, consider:"
echo "- Configuring specific services for your workload"
echo "- Implementing full monitoring solution (Prometheus/Grafana)"
echo "- Setting up backup strategy"
echo "- Regular security audits with OpenSCAP"
