#!/bin/bash

# CentOS Specific Optimization Script

set -e

echo "Starting CentOS specific optimization..."

# 1. Show CentOS version
echo "1. CentOS version:"
 cat /etc/centos-release
 echo ""

# 2. Update system to latest packages
echo "2. Updating system to latest packages..."
sudo dnf update -y
 echo ""

# 3. Enable EPEL repository
echo "3. Enabling EPEL repository..."
sudo dnf install -y epel-release
 echo "EPEL repository enabled."
 echo ""

# 4. Server-specific service optimization
echo "4. Optimizing server services..."

# Disable unnecessary services for servers
services_to_disable=("bluetooth" "cups" "avahi-daemon" "chronyd" "postfix" "firewalld" "NetworkManager")

for service in "${services_to_disable[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Disabling $service..."
        sudo systemctl disable --now "$service"
    fi
done

# Enable necessary server services
services_to_enable=("sshd" "crond" "rsyslog")

for service in "${services_to_enable[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        echo "Enabling $service..."
        sudo systemctl enable --now "$service"
    fi
done

echo "Server services optimized."
echo ""

# 5. Security hardening
echo "5. Security hardening..."

# Install security packages
sudo dnf install -y fail2ban openscap-scanner scap-security-guide

# Enable fail2ban
sudo systemctl enable --now fail2ban

# Configure fail2ban for SSH
sudo tee /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
banaction = iptables-multiport
chain = INPUT
ports = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 86400
bantime = 86400
EOF

sudo systemctl restart fail2ban

echo "Security hardening completed."
echo ""

# 6. Server performance tuning
echo "6. Server performance tuning..."

# Optimize sysctl settings for servers
sudo tee -a /etc/sysctl.conf <<EOF

# Server performance optimization
# Increase file descriptor limits
fs.file-max = 65535

# Increase TCP connection limits
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096

# Optimize TCP buffers
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Optimize TCP recycling and timeouts
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000

# Enable SYN cookies
net.ipv4.tcp_syncookies = 1

# Optimize memory management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

# Apply sysctl settings
sudo sysctl -p

echo "Server performance tuning completed."
echo ""

# 7. SELinux optimization for servers
echo "7. Optimizing SELinux for servers..."

# Ensure SELinux is in enforcing mode
echo "Setting SELinux to enforcing mode..."
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Install SELinux utilities
sudo dnf install -y policycoreutils-python-utils

echo "SELinux optimization completed."
echo ""

# 8. Log management optimization
echo "8. Optimizing log management..."

# Install logrotate if not installed
sudo dnf install -y logrotate

# Optimize logrotate configuration for servers
sudo tee -a /etc/logrotate.conf <<EOF

# Server log rotation settings
weekly
rotate 4
create
compress
delaycompress
missingok
notifempty
EOF

# Set up logwatch for daily log reports
sudo dnf install -y logwatch

echo "0 0 * * * /usr/sbin/logwatch --output mail --mailto root --detail high" | sudo tee -a /etc/cron.d/logwatch

echo "Log management optimization completed."
echo ""

# 9. Disk I/O optimization
echo "9. Optimizing disk I/O..."

# Show current disk I/O scheduler
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

# 10. Kernel optimization for servers
echo "10. Optimizing kernel for servers..."

# Install kernel tools
sudo dnf install -y kernel-tools

# Configure tuned profile for servers
sudo dnf install -y tuned
sudo systemctl enable --now tuned

echo "Available tuned profiles:"
tuned-adm list

echo "Setting tuned profile to throughput-performance..."
sudo tuned-adm profile throughput-performance

echo "Kernel optimization completed."
echo ""

# 11. Clean up unnecessary packages
echo "11. Cleaning up unnecessary packages..."
sudo dnf autoremove -y
sudo dnf clean all

echo "Cleanup completed."

# 12. Show final optimization summary
echo "12. CentOS server optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- EPEL repository enabled"
echo "- Unnecessary services disabled"
echo "- Server services enabled"
echo "- Security hardening with fail2ban"
echo "- Server performance tuning with sysctl"
echo "- SELinux set to enforcing mode"
echo "- Log management optimized with logwatch"
echo "- Disk I/O scheduler set to mq-deadline"
echo "- Tuned profile set to throughput-performance"
echo "- System cleaned up"
echo ""
echo "Reboot your system to apply all changes completely."
echo "For further optimization, consider:"
echo "- Configuring specific services for your workload"
echo "- Implementing monitoring with Prometheus/Grafana"
echo "- Setting up backup solutions"
echo "- Implementing a load balancer (for multiple servers)"
