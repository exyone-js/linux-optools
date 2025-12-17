#!/bin/bash

# Clean Package Cache and Unused Packages for Debian-like Systems

set -e

echo "Starting package cleanup process..."

# 1. Show disk usage before cleanup
echo "1. Disk usage before cleanup:"
df -h /

# 2. Update package lists first
echo "\n2. Updating package lists..."
sudo apt update

# 3. Clean APT cache
echo "\n3. Cleaning APT cache..."
sudo apt clean

# 4. Remove unused dependencies
echo "\n4. Removing unused dependencies..."
sudo apt autoremove --purge -y

# 5. Remove old kernels
echo "\n5. Removing old kernels..."
# Keep only the current and one previous kernel
sudo apt install -y byobu 2>/dev/null || true  # Install byobu for purge-old-kernels
if command -v purge-old-kernels &> /dev/null; then
    sudo purge-old-kernels --keep 1 -y
else
    # Alternative method to remove old kernels
    CURRENT_KERNEL=$(uname -r | sed 's/-[a-z].*//')
    OLD_KERNELS=$(dpkg --list | grep -E 'linux-image-[0-9]' | grep -v "$CURRENT_KERNEL" | awk '{print $2}' || true)
    if [ -n "$OLD_KERNELS" ]; then
        echo "Found old kernels: $OLD_KERNELS"
        echo "Removing old kernels..."
        sudo apt remove --purge -y $OLD_KERNELS
    else
        echo "No old kernels found to remove."
    fi
fi

# 6. Remove orphaned packages
echo "\n6. Removing orphaned packages..."
if command -v deborphan &> /dev/null; then
    sudo deborphan | xargs -r sudo apt remove --purge -y
else
    echo "Installing deborphan..."
    sudo apt install -y deborphan
    sudo deborphan | xargs -r sudo apt remove --purge -y
fi

# 7. Clean old configuration files
echo "\n7. Cleaning old configuration files..."
sudo dpkg --purge $(dpkg -l | grep '^rc' | awk '{print $2}') 2>/dev/null || true

# 8. Clean snap packages (for Ubuntu with snap)
echo "\n8. Cleaning snap packages..."
if command -v snap &> /dev/null; then
    # Remove old snap revisions
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
    done
    # Clean snap cache
    sudo rm -rf /var/lib/snapd/cache/* 2>/dev/null || true
fi

# 9. Clean flatpak packages (if installed)
echo "\n9. Cleaning flatpak packages..."
if command -v flatpak &> /dev/null; then
    flatpak uninstall --unused -y
    flatpak repair -y
fi

# 10. Clean temporary files
echo "\n10. Cleaning temporary files..."
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

# 11. Show disk usage after cleanup
echo "\n11. Disk usage after cleanup:"
df -h /

# 12. Show summary of cleaned items
echo "\n12. Cleanup summary:"
echo "  - APT cache cleaned"
echo "  - Unused dependencies removed"
echo "  - Old kernels removed"
echo "  - Orphaned packages removed"
echo "  - Old configuration files cleaned"
if command -v snap &> /dev/null; then
    echo "  - Old snap revisions removed"
fi
if command -v flatpak &> /dev/null; then
    echo "  - Unused flatpak packages removed"
fi
echo "  - Temporary files cleaned"

echo "\nPackage cleanup completed successfully!"
echo "Use 'sudo apt update && sudo apt upgrade' to keep your system updated."