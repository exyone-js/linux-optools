#!/bin/bash

# Snap Performance Optimization Script for Ubuntu

set -e

echo "Starting Snap performance optimization..."

# 1. Check if snap is installed
if ! command -v snap &> /dev/null; then
    echo "Error: snap is not installed. This script is for systems with snap installed."
    exit 1
fi

# 2. Update snap to latest version
echo "1. Updating snapd to latest version..."
sudo snap install core

# 3. Optimize snap refresh settings
echo "\n2. Optimizing snap refresh settings..."
# Set refresh timer to non-peak hours (2 AM - 4 AM)
sudo snap set system refresh.timer="02:00-04:00"

# 4. Reduce snap refresh frequency
echo "\n3. Reducing snap refresh frequency..."
# Set refresh hold to 7 days (default is 4 days)
sudo snap set system refresh.hold="7d"

# 5. Optimize snap mount options
echo "\n4. Optimizing snap mount options..."
# Check current snap mount options
SNAP_MOUNT=$(mount | grep snap | head -1 | awk '{print $6}')
if [ -n "$SNAP_MOUNT" ]; then
    echo "Current snap mount point: $SNAP_MOUNT"
    echo "Current mount options: $(mount | grep snap | head -1 | awk '{print $5}')"
fi

# 6. Disable snap autostart apps
echo "\n5. Disabling snap autostart applications..."
# List autostart snap applications
autostart_dir="$HOME/.config/autostart"
if [ -d "$autostart_dir" ]; then
    snap_autostart_files=$(find "$autostart_dir" -name "*.desktop" | xargs grep -l "X-SnapInstanceName" 2>/dev/null || true)
    if [ -n "$snap_autostart_files" ]; then
        echo "Found snap autostart files: $snap_autostart_files"
        echo "Disabling snap autostart applications..."
        for file in $snap_autostart_files; do
            echo "Disabling $file"
            mv "$file" "$file.disabled"
        done
    else
        echo "No snap autostart applications found."
    fi
fi

# 7. Optimize snap disk usage
echo "\n6. Optimizing snap disk usage..."
sudo snap list --all | grep disabled | awk '{print $1, $3}' | while read snapname revision; do
    echo "Removing disabled revision $revision of $snapname..."
    sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
done

# 8. Clean snap cache
echo "\n7. Cleaning snap cache..."
sudo rm -rf /var/lib/snapd/cache/* 2>/dev/null || true

# 9. Show snap status
echo "\n8. Current snap status:"
echo "=== Snap Version ==="
snap version
echo "\n=== Snap Refresh Settings ==="
snap get system refresh

# 10. Show installed snaps
echo "\n=== Installed Snap Applications ==="
snap list

# 11. Show snap disk usage
echo "\n=== Snap Disk Usage ==="
du -sh /var/lib/snapd/ 2>/dev/null || true
du -sh ~/snap/ 2>/dev/null || true

# 12. Recommendations
echo "\n9. Recommendations:"
echo "  - Use 'sudo snap refresh --hold=<days>' to further delay snap updates"
echo "  - Use 'sudo snap refresh <app>' to manually update specific apps"
echo "  - Use 'snap list --all' to see all installed revisions"
echo "  - Consider using 'snap-store' to manage snaps with a GUI"
echo "  - For better performance, consider using native deb packages instead of snaps when available"

echo "\nSnap optimization completed successfully!"