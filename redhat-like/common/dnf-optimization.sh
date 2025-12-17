#!/bin/bash

# DNF Package Manager Optimization for Red Hat-like Systems

set -e

echo "Starting DNF package manager optimization..."

# 1. Check if DNF is installed
if ! command -v dnf &> /dev/null; then
    echo "Error: dnf is not installed. This script is for systems with DNF package manager."
    exit 1
fi

# 2. Show current DNF configuration
echo "1. Current DNF configuration:"
cat /etc/dnf/dnf.conf 2>/dev/null || echo "DNF configuration file not found"
echo ""

# 3. Backup current DNF configuration
echo "2. Backing up current DNF configuration..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
sudo cp /etc/dnf/dnf.conf "/etc/dnf/dnf.conf.backup_$TIMESTAMP" 2>/dev/null || true

# 4. Optimize DNF configuration
echo "3. Optimizing DNF configuration..."
sudo tee -a /etc/dnf/dnf.conf <<EOF

# DNF Optimization Settings
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
timeout=300
minrate=1000
install_weak_deps=False
cacheonly=False
keepcache=False
EOF

# 5. Enable DNF fastestmirror plugin
echo "4. Enabling DNF plugins..."
# Install required plugins if not already installed
sudo dnf install -y dnf-plugins-core fastestmirror 2>/dev/null || true

# 6. Clean DNF cache
echo "5. Cleaning DNF cache..."
sudo dnf clean all

# 7. Update DNF metadata
echo "6. Updating DNF metadata..."
sudo dnf makecache

# 8. Enable DNF automatic updates (optional)
echo "7. Configuring DNF automatic updates..."
echo "Available options:"
echo "1. Enable daily automatic updates"
echo "2. Enable weekly automatic updates"
echo "3. Skip automatic updates configuration"
echo ""
read -p "Enter your choice (1-3): " update_choice

echo ""
case $update_choice in
    1)
        echo "Enabling daily automatic updates..."
        sudo dnf install -y dnf-automatic
        sudo sed -i 's/^apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
        sudo systemctl enable --now dnf-automatic.timer
        ;;
    2)
        echo "Enabling weekly automatic updates..."
        sudo dnf install -y dnf-automatic
        sudo sed -i 's/^apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
        sudo systemctl enable --now dnf-automatic-weekly.timer
        ;;
    3)
        echo "Skipping automatic updates configuration."
        ;;
    *)
        echo "Invalid choice, skipping automatic updates configuration."
        ;;
esac

# 9. Show optimized DNF configuration
echo "\n8. Optimized DNF configuration:"
cat /etc/dnf/dnf.conf

# 10. Show DNF plugins
echo "\n9. Enabled DNF plugins:"
dnf pluginlist enabled

# 11. Show disk usage before and after
echo "\n10. DNF cache disk usage:"
du -sh /var/cache/dnf/ 2>/dev/null || echo "DNF cache directory not found"

echo "\nDNF optimization completed successfully!"
echo "Key optimizations applied:"
echo "  - Enabled fastestmirror plugin"
echo "  - Increased parallel downloads to 10"
echo "  - Set defaultyes to True for non-interactive installs"
echo "  - Increased timeout to 300 seconds"
echo "  - Set minimum download rate to 1000 B/s"
echo "  - Disabled weak dependencies installation"
echo "  - Disabled cache keeping after installation"
echo "  - Cleaned and updated DNF cache"
