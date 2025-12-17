#!/bin/bash

# Arch Linux Server Optimization Script

set -e

echo "Starting Arch Linux server optimization..."

# 1. Update system
echo "1. Updating system..."
sudo pacman -Syu --noconfirm
echo ""

# 2. Install essential server packages
echo "2. Installing essential server packages..."
sudo pacman -S --noconfirm --needed base-devel openssh ntp chrony fail2ban ufw git curl wget htop iotop iperf3 rsync
echo "Essential server packages installed."
echo ""

# 3. Configure SSH for security
echo "3. Configuring SSH for security..."

# Backup original SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Apply SSH hardening
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sudo sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#MaxSessions.*/MaxSessions 10/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart sshd
sudo systemctl enable sshd

echo "SSH configured for security."
echo ""

# 4. Configure time synchronization
echo "4. Configuring time synchronization..."

# Choose between Chrony and NTP based on availability
if command -v chronyd &> /dev/null; then
    echo "Using Chrony for time synchronization..."
    sudo systemctl enable --now chronyd
    sudo chronyc sources
elif command -v ntpd &> /dev/null; then
    echo "Using NTP for time synchronization..."
    sudo systemctl enable --now ntpd
    sudo ntpq -p
fi

echo "Time synchronization configured."
echo ""

# 5. Configure firewall with UFW
echo "5. Configuring firewall with UFW..."

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 22/tcp  # SSH (redundant but explicit)

echo "Enabling UFW firewall..."
sudo ufw --force enable
sudo ufw status verbose

echo "UFW firewall configured."
echo ""

# 6. Configure Fail2ban for SSH protection
echo "6. Configuring Fail2ban for SSH protection..."

# Start and enable Fail2ban
sudo systemctl enable --now fail2ban

# Create SSH jail configuration
sudo cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 1800
EOF

# Restart Fail2ban
sudo systemctl restart fail2ban
echo "Fail2ban status:"
sudo fail2ban-client status
echo ""

# 7. Install and configure monitoring tools
echo "7. Installing monitoring tools..."

sudo pacman -S --noconfirm --needed prometheus node_exporter grafana
echo "Monitoring tools installed."

# Enable monitoring services
echo "Enabling monitoring services..."
sudo systemctl enable --now prometheus
sudo systemctl enable --now node_exporter
sudo systemctl enable --now grafana
echo "Monitoring services enabled."
echo ""

# 8. Install and configure backup solution
echo "8. Installing backup solution..."

sudo pacman -S --noconfirm --needed borg borgmatic python-packaging

echo "Backup solution installed."

# Create backup directory
sudo mkdir -p /var/backup

echo "Backup configuration:"
echo "- Installed Borg and Borgmatic"
echo "- Created backup directory at /var/backup"
echo "- Please configure Borgmatic by editing /etc/borgmatic/config.yaml"
echo ""

# 9. Install web server stack (Apache/MySQL/PHP)
echo "9. Installing web server stack (Apache/MySQL/PHP)..."
echo "Press Enter to continue or Ctrl+C to skip..."
read -r

sudo pacman -S --noconfirm --needed apache mariadb php php-apache php-mysql php-gd php-intl php-mcrypt php-pgsql
echo "Web server stack installed."

# Configure Apache
echo "Configuring Apache..."
sudo sed -i 's/^#LoadModule rewrite_module modules\/mod_rewrite.so/LoadModule rewrite_module modules\/mod_rewrite.so/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/^AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
sudo systemctl enable --now httpd

# Secure MySQL/MariaDB
echo "Securing MariaDB..."
sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable --now mariadb
sudo mysql_secure_installation

echo "Web server stack configured."
echo ""

# 10. Optimize system performance
echo "10. Optimizing system performance..."

# Configure sysctl for server workloads
echo "Configuring sysctl..."
sudo cat > /etc/sysctl.d/99-server.conf <<EOF
# Server optimization settings

# Network optimizations
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Memory optimizations
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# File descriptor limits
fs.file-max = 65536
EOF

# Apply sysctl changes
sudo sysctl --system

# Configure limits.conf
echo "Configuring limits.conf..."
sudo cat >> /etc/security/limits.conf <<EOF

# Increase file descriptor limits
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF

echo "System performance optimized."
echo ""

# 11. Install log management
echo "11. Installing log management..."

sudo pacman -S --noconfirm --needed logrotate rsyslog
echo "Log management tools installed."

# Enable rsyslog
sudo systemctl enable --now rsyslog

echo "Log management configured."
echo ""

# 12. Install and configure Docker (optional)
echo "12. Installing Docker (optional)..."
echo "Press Enter to continue or Ctrl+C to skip..."
read -r

sudo pacman -S --noconfirm --needed docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
echo "Docker installed and enabled. Please logout and login to apply group changes."
echo ""

# 13. Final cleanup and recommendations
echo "13. Final cleanup..."
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true
sudo pacman -Scc --noconfirm

echo "Cleanup completed."

# 14. Show final optimization summary
echo "14. Arch Linux server optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- Essential server packages installed"
echo "- SSH configured for security"
echo "- Time synchronization with Chrony/NTP"
echo "- Firewall configured with UFW"
echo "- Fail2ban configured for SSH protection"
echo "- Monitoring tools installed (Prometheus, Grafana)"
echo "- Backup solution with Borg and Borgmatic"
echo "- Web server stack installed and configured"
echo "- System performance optimized for server workloads"
echo "- Log management configured"
echo "- Docker installed (optional)"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to apply all changes"
echo "- Configure Borgmatic backup schedule"
echo "- Set up SSL certificates for web services"
echo "- Configure regular system updates"
echo "- Monitor system performance with Grafana"
echo "- Implement a disaster recovery plan"
echo "- Consider installing a web application firewall"