#!/bin/bash

# Update Software Mirrors for Debian-like Systems

set -e

echo "Starting software mirrors update..."

# 1. Detecting the distribution
DEBIAN_VERSION=$(grep -E '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d= -f2)
UBUNTU_VERSION=$(grep -E '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2)

if [ -f /etc/debian_version ] && [ -z "$UBUNTU_VERSION" ]; then
    DISTRO="debian"
    MIRROR_LIST_URL="https://www.debian.org/mirror/list"
elif [ -f /etc/lsb-release ] || [ -n "$UBUNTU_VERSION" ]; then
    DISTRO="ubuntu"
    MIRROR_LIST_URL="https://launchpad.net/ubuntu/+archivemirrors"
else
    echo "Error: Unsupported distribution. This script is for Debian/Ubuntu only."
    exit 1
fi

echo "Detected distribution: $DISTRO"

# 2. Backing up current sources.list
echo "2. Backing up current sources.list..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
sudo cp /etc/apt/sources.list "/etc/apt/sources.list.backup_$TIMESTAMP"
if [ -d /etc/apt/sources.list.d ]; then
    sudo cp -r /etc/apt/sources.list.d "/etc/apt/sources.list.d.backup_$TIMESTAMP"
fi

# 3. Updating mirrors based on distribution
if [ "$DISTRO" = "debian" ]; then
    echo "3. Updating Debian mirrors..."
    # Use official Debian mirrors
    # You can replace with your preferred mirror country
    COUNTRY="us"  # Change to your country code (e.g., cn, uk, de)
    
    sudo tee /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian $DEBIAN_VERSION main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $DEBIAN_VERSION main contrib non-free non-free-firmware

deb http://deb.debian.org/debian-security/ $DEBIAN_VERSION-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security/ $DEBIAN_VERSION-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
EOF
    
elif [ "$DISTRO" = "ubuntu" ]; then
    echo "3. Updating Ubuntu mirrors..."
    # Use official Ubuntu mirrors or fastest mirror
    
    # Option 1: Use official mirror
    # sudo tee /etc/apt/sources.list <<EOF
    # deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
    # deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
    # deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
    # deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
    # EOF
    
    # Option 2: Use fastest mirror (recommended)
    echo "Installing apt-fast to use fastest mirror..."
    sudo apt update && sudo apt install -y apt-fast
    
    # Configure apt-fast to use fastest mirror
    sudo sed -i 's/^#AUTOSELECT_MIRROR=.*/AUTOSELECT_MIRROR=1/' /etc/apt-fast.conf
fi

# 4. Updating package lists
echo "4. Updating package lists..."
sudo apt update

# 5. Cleaning up old packages
echo "5. Cleaning up old packages..."
sudo apt autoremove -y
sudo apt clean

# 6. Showing current mirrors
echo "6. Current software mirrors:"
echo "=== /etc/apt/sources.list ==="
cat /etc/apt/sources.list

if [ -d /etc/apt/sources.list.d ] && [ "$(ls -A /etc/apt/sources.list.d)" ]; then
    echo "\n=== /etc/apt/sources.list.d/ ==="
    ls -la /etc/apt/sources.list.d/
fi

echo "\nSoftware mirrors update completed successfully!"
echo "Key changes made:"
echo "  - Backed up original sources.list to /etc/apt/sources.list.backup_$TIMESTAMP"
echo "  - Updated $DISTRO software mirrors"
echo "  - Updated package lists"
echo "  - Cleaned up old packages"
echo "\nTo restore original mirrors: sudo cp /etc/apt/sources.list.backup_$TIMESTAMP /etc/apt/sources.list && sudo apt update"