#!/bin/bash

# Zypper Package Manager Optimization for openSUSE

set -e

echo "Starting Zypper package manager optimization..."

# 1. Check if Zypper is installed
if ! command -v zypper &> /dev/null; then
    echo "Error: zypper is not installed. This script is for systems with Zypper package manager."
    exit 1
fi

# 2. Show current Zypper configuration
echo "1. Current Zypper configuration:"
zypper lr
 echo ""

# 3. Backup current Zypper configuration
echo "2. Backing up current Zypper configuration..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
sudo cp /etc/zypp/zypp.conf "/etc/zypp/zypp.conf.backup_$TIMESTAMP"

# 4. Optimize Zypper configuration
echo "3. Optimizing Zypper configuration..."

# Enable color output
sudo sed -i 's/^# solver.allowVendorChange.*/solver.allowVendorChange = true/' /etc/zypp/zypp.conf
sudo sed -i 's/^# color.*/color = always/' /etc/zypp/zypp.conf

# Increase download parallelism
sudo sed -i 's/^download.max_concurrent_connections.*/download.max_concurrent_connections = 10/' /etc/zypp/zypp.conf
sudo sed -i 's/^download.max_speed.*/download.max_speed = 0/' /etc/zypp/zypp.conf

# Enable auto-refresh
sudo sed -i 's/^# autorefresh.*/autorefresh = true/' /etc/zypp/zypp.conf

# Enable delta RPMs for faster downloads
sudo sed -i 's/^# download.use_deltarpm.*/download.use_deltarpm = true/' /etc/zypp/zypp.conf
sudo sed -i 's/^# solver.deltarpms.*/solver.deltarpms = true/' /etc/zypp/zypp.conf

# Set keep-packages to false to save disk space
sudo sed -i 's/^# keep-packages.*/keep-packages = false/' /etc/zypp/zypp.conf

# 5. Add additional repositories if needed
echo "4. Adding additional repositories..."
read -p "Do you want to add Packman repository? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Adding Packman repository..."
    sudo zypper addrepo --refresh https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_$(grep VERSION_ID /etc/os-release | cut -d= -f2)/ Packman
    sudo zypper --gpg-auto-import-keys refresh
    echo "Packman repository added."
fi

echo ""

# 6. Update system to latest packages
echo "5. Updating system to latest packages..."
sudo zypper update -y

echo "System updated."
echo ""

# 7. Clean Zypper cache
echo "6. Cleaning Zypper cache..."
sudo zypper clean -a

echo "Cache cleaned."
echo ""

# 8. Install recommended packages
echo "7. Installing recommended packages..."
sudo zypper install -y --type pattern devel_basis 
sudo zypper install -y --type pattern enhanced_base 
sudo zypper install -y --type pattern fonts 
sudo zypper install -y --type pattern multimedia 

echo "Recommended packages installed."
echo ""

# 9. Enable and configure Btrfs snapshots (if using Btrfs)
echo "8. Checking for Btrfs..."
if mount | grep -q "btrfs" && command -v snapper &> /dev/null; then
    echo "Btrfs detected. Enabling snapper..."
    
    # Check if snapper is already configured
    if ! snapper list-configs | grep -q "root"; then
        echo "Configuring snapper for root filesystem..."
        sudo snapper create-config /
    fi
    
    echo "Enabling snapper-timeline service..."
    sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
    
    echo "Snapper configured."
else
    echo "Btrfs or snapper not detected. Skipping snapper configuration."
fi
echo ""

# 10. Enable and configure firewalld
echo "9. Enabling firewalld..."
sudo systemctl enable --now firewalld
echo "firewalld enabled."
echo ""

# 11. Show optimized Zypper configuration
echo "10. Optimized Zypper repositories:"
zypper lr
 echo ""

# 12. Final recommendations
echo "11. Zypper optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- Zypper configuration optimized with color output"
echo "- Increased parallel downloads to 10"
echo "- Enabled delta RPMs for faster downloads"
echo "- Enabled auto-refresh for repositories"
echo "- Added Packman repository (optional)"
echo "- System updated to latest packages"
echo "- Zypper cache cleaned"
echo "- Recommended packages installed"
echo "- Btrfs snapshots enabled (if applicable)"
echo "- firewalld enabled"
echo ""
echo "Recommended commands:"
echo "- Update system: sudo zypper update"
echo "- Install package: sudo zypper install <package>"
echo "- Remove package: sudo zypper remove <package>"
echo "- Search package: sudo zypper search <package>"
echo "- List repositories: sudo zypper lr"
echo "- Refresh repositories: sudo zypper refresh"
echo "- Clean cache: sudo zypper clean -a"