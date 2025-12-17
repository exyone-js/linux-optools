# Linux System Security Hardening Script

echo "Starting system security hardening..."

# 1. Password Policy Hardening
echo "1. Hardening password policy..."
sudo tee -a /etc/security/pwquality.conf <<EOF
# Password complexity requirements
minlen = 12
minclass = 3
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 3
maxrepeat = 3
maxclassrepeat = 2
enforce_for_root
EOF

# Set password expiration policy
sudo tee -a /etc/login.defs <<EOF
# Password expiration settings
PASS_MAX_DAYS 90
PASS_MIN_DAYS 7
PASS_WARN_AGE 14
EOF

# 2. SSH Security Configuration
echo "2. Optimizing SSH security configuration..."
# Backup original configuration
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Apply SSH security configuration
sudo tee -a /etc/ssh/sshd_config <<EOF

# Security hardening configuration
PermitRootLogin no
PermitEmptyPasswords no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
# Allowed users (modify according to actual situation)
# AllowUsers your_username
# Disable DNS reverse lookup
UseDNS no
EOF

# Restart SSH service
sudo systemctl restart sshd

# 3. Basic Firewall Configuration
echo "3. Configuring firewall..."
# Check and enable firewalld or ufw
if command -v firewalld &> /dev/null; then
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    sudo firewall-cmd --set-default-zone=drop
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw enable
fi

# 4. Disable Unnecessary Services
echo "4. Disabling unnecessary services..."
# Disable IPv6 (if not needed)
# sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
# sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Disable unnecessary system services
services_to_disable=("avahi-daemon" "bluetooth" "cups" "pcscd" "saned" "ModemManager")
for service in "${services_to_disable[@]}"; do
    if systemctl list-unit-files | grep -q "^$service\.service"; then
        sudo systemctl disable --now "$service"
    fi
done

# 5. Permission Hardening
echo "5. Hardening file and directory permissions..."
# Harden sensitive file permissions
sudo chmod 600 /etc/shadow
sudo chmod 644 /etc/passwd

# 6. Log Security
echo "6. Optimizing log configuration..."
# Ensure rsyslog or journald is running
if command -v rsyslogd &> /dev/null; then
    sudo systemctl enable --now rsyslog
fi

# 7. Disable Dangerous System Calls
echo "7. Disabling dangerous system calls..."
sudo tee -a /etc/sysctl.conf <<EOF

# Security hardening configuration
# Disable SYN flood attacks
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable IP forwarding (if not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
EOF

# Apply sysctl configuration
sudo sysctl -p

# 8. Install Security Updates
echo "8. Installing security updates..."
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt upgrade -y
elif command -v dnf &> /dev/null; then
    sudo dnf update -y
elif command -v yum &> /dev/null; then
    sudo yum update -y
fi

echo "System security hardening completed!"
echo "Recommended further actions:"
echo "  - Install fail2ban: sudo apt install fail2ban or sudo dnf install fail2ban"
echo "  - Configure SELinux/AppArmor"
echo "  - Regularly update system and packages"
echo "  - Consider using key authentication instead of password authentication for SSH"