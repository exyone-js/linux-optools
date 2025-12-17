#!/bin/bash

# openSUSE Leap Specific Optimization Script

set -e

echo "Starting openSUSE Leap specific optimization..."

# 1. Show Leap version
echo "1. openSUSE Leap version:"
 cat /etc/os-release
 echo ""

# 2. Update system to latest packages
echo "2. Updating system to latest packages..."
sudo zypper update -y
 echo ""

# 3. Enable essential repositories
echo "3. Enabling essential repositories..."

# Ensure Packman is enabled
if ! zypper lr | grep -q "Packman"; then
    echo "Adding Packman repository..."
    LEAP_VERSION=$(grep VERSION_ID /etc/os-release | cut -d= -f2)
    sudo zypper addrepo --refresh https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$LEAP_VERSION/ Packman
fi

# Ensure Update repository is enabled
echo "Ensuring Update repository is enabled..."
sudo zypper modifyrepo --enable repo-update

# Ensure Non-OSS repository is enabled
echo "Ensuring Non-OSS repository is enabled..."
sudo zypper modifyrepo --enable repo-non-oss

echo "Refreshing repositories..."
sudo zypper --gpg-auto-import-keys refresh

echo "Repositories enabled."
echo ""

# 4. Install Leap specific packages
echo "4. Installing Leap specific packages..."
sudo zypper install -y --type pattern devel_basis 
sudo zypper install -y --type pattern enhanced_base 
sudo zypper install -y --type pattern fonts 
sudo zypper install -y --type pattern multimedia 
sudo zypper install -y --type pattern server_apps 

echo "Leap specific packages installed."
echo ""

# 5. Optimize for desktop usage
echo "5. Optimizing for desktop usage..."

# Check if this is a desktop
desktop=false
if command -v gnome-session &> /dev/null || command -v startkde &> /dev/null || command -v startxfce4 &> /dev/null; then
    desktop=true
fi

if $desktop; then
    echo "Desktop environment detected. Installing desktop optimizations..."
    
    # Install desktop specific packages
    sudo zypper install -y --type pattern gnome 
    sudo zypper install -y --type pattern kde 
    sudo zypper install -y --type pattern xfce 
    
    # Enable desktop services
    sudo systemctl enable --now NetworkManager 
    sudo systemctl enable --now avahi-daemon 
    
    echo "Desktop optimizations installed."
else
    echo "Server environment detected. Skipping desktop optimizations."
fi
echo ""

# 6. Enable and configure power management
echo "6. Configuring power management..."

# For laptops
if grep -q "^DMI:.*[Ll]aptop" /sys/class/dmi/id/chassis_type 2>/dev/null || grep -q "^Chassis\s*Type:\s*10" /proc/cpuinfo 2>/dev/null; then
    echo "Laptop detected. Installing power management packages..."
    sudo zypper install -y tlp powertop thermald 
    
    # Enable TLP
    sudo systemctl enable --now tlp tlp-rdw 
    
    # Run powertop auto-tune
    sudo powertop --auto-tune 
    
    # Enable thermald
    sudo systemctl enable --now thermald 
    
    echo "Laptop power management configured."
else
    echo "Desktop detected. Skipping laptop power management."
fi
echo ""

# 7. Enable Btrfs snapshots with snapper
echo "7. Enabling Btrfs snapshots with snapper..."

# Check if using Btrfs
if mount | grep -q "btrfs" && command -v snapper &> /dev/null; then
    echo "Btrfs detected. Configuring snapper..."
    
    # Check if snapper is already configured for root
    if ! snapper list-configs | grep -q "root"; then
        echo "Creating snapper configuration for root..."
        sudo snapper create-config /
    fi
    
    # Enable snapper services
    sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer 
    
    # Configure snapper cleanup policies
    echo "Configuring snapper cleanup policies..."
    sudo snapper set-config "TIMELINE_LIMIT_HOURLY=10"
    sudo snapper set-config "TIMELINE_LIMIT_DAILY=10"
    sudo snapper set-config "TIMELINE_LIMIT_WEEKLY=0"
    sudo snapper set-config "TIMELINE_LIMIT_MONTHLY=0"
    sudo snapper set-config "TIMELINE_LIMIT_YEARLY=0"
    
    echo "snapper configured."
else
    echo "Btrfs or snapper not detected. Skipping snapper configuration."
fi
echo ""

# 8. Enable firewalld
echo "8. Enabling firewalld..."
sudo systemctl enable --now firewalld 

# Open common ports
echo "Opening common ports..."
sudo firewall-cmd --permanent --add-service=ssh 
sudo firewall-cmd --permanent --add-service=http 
sudo firewall-cmd --permanent --add-service=https 
sudo firewall-cmd --reload 

echo "firewalld enabled and configured."
echo ""

# 9. Security hardening
echo "9. Security hardening..."

# Install additional security packages
sudo zypper install -y openscap-scanner scap-security-guide fail2ban 

# Enable fail2ban
sudo systemctl enable --now fail2ban 

echo "Security hardening completed."
echo ""

# 10. Configure ZRAM for better performance
echo "10. Configuring ZRAM..."

if ! command -v zramctl &> /dev/null; then
    echo "Installing zram-generator..."
    sudo zypper install -y zram-generator 
fi

# Create zram configuration
echo "Creating zram configuration..."
sudo tee /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

sudo systemctl daemon-reload 
sudo systemctl enable --now /dev/zram0.swap 

echo "ZRAM configured."
echo ""

# 11. Cleanup unnecessary packages
echo "11. Cleaning up unnecessary packages..."
sudo zypper remove --clean-deps -y $(zypper packages --unneeded -i | awk 'NR>2 {print $3}') 2>/dev/null || true
sudo zypper clean -a 

echo "Cleanup completed."
echo ""

# 12. Show final optimization summary
echo "12. openSUSE Leap optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- Essential repositories enabled"
echo "- Leap specific packages installed"
echo "- Desktop optimizations applied (if desktop detected)"
echo "- Power management configured (for laptops)"
echo "- Btrfs snapshots enabled with snapper (if using Btrfs)"
echo "- firewalld enabled and configured"
echo "- Security hardening applied"
echo "- ZRAM configured for better performance"
echo "- System cleaned up"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to apply all changes"
echo "- Run 'sudo snapper list' to see Btrfs snapshots"
echo "- Use 'zypper dup' for distribution upgrades"
echo "- Regularly run 'sudo zypper update' to keep your system updated"
echo "- Check 'YaST Control Center' for additional system configuration"