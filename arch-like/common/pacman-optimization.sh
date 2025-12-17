#!/bin/bash

# Pacman Package Manager Optimization for Arch-like Systems

set -e

echo "Starting Pacman package manager optimization..."

# 1. Check if Pacman is installed
if ! command -v pacman &> /dev/null; then
    echo "Error: pacman is not installed. This script is for systems with Pacman package manager."
    exit 1
fi

# 2. Show current Pacman configuration
echo "1. Current Pacman configuration:"
cat /etc/pacman.conf | grep -v '^#\|^$' || echo "Pacman configuration file not found"
echo ""

# 3. Backup current Pacman configuration
echo "2. Backing up current Pacman configuration..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
sudo cp /etc/pacman.conf "/etc/pacman.conf.backup_$TIMESTAMP"

# 4. Optimize Pacman configuration
echo "3. Optimizing Pacman configuration..."

# Create a backup of the original configuration
ORIGINAL_CONFIG=$(cat /etc/pacman.conf)

# Apply optimizations using sed

# Enable color output
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

# Enable parallel downloads (set to 10)
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf

# Enable ILoveCandy (just for fun, optional)
echo "Enabling ILoveCandy animation..."
sudo sed -i 's/^#ILoveCandy/ILoveCandy/' /etc/pacman.conf

# Enable multilib repository
echo "Enabling multilib repository..."
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

# Add additional repositories if needed
echo "Adding additional repositories (Chaotic-AUR is optional)..."
read -p "Do you want to add Chaotic-AUR repository? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Add Chaotic-AUR repository
    sudo pacman-key --recv-key FBA4E0A2871F16537A48C2FEB6430107F4A319E8
    sudo pacman-key --lsign-key FBA4E0A2871F16537A48C2FEB6430107F4A319E8
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    
    # Install chaotic-mirrorlist
    sudo pacman -Syu --noconfirm chaotic-mirrorlist 2>/dev/null || {
        echo "Failed to install chaotic-mirrorlist. Please install manually."
    }
fi

# 5. Update Pacman databases
echo "4. Updating Pacman databases..."
sudo pacman -Sy

# 6. Clean Pacman cache
echo "5. Cleaning Pacman cache..."
echo "Available cache cleanup options:"
echo "1. Remove all cached packages except the latest version"
echo "2. Remove all cached packages"
echo "3. Skip cache cleanup"
echo ""

read -p "Enter your choice (1-3): " cache_choice

case $cache_choice in
    1)
        echo "Removing old cached packages..."
        paccache -r
        ;;
    2)
        echo "Removing all cached packages..."
        paccache -rk0
        ;;
    3)
        echo "Skipping cache cleanup."
        ;;
    *)
        echo "Invalid choice. Skipping cache cleanup."
        ;;
esac
echo ""

# 7. Install useful Pacman utilities
echo "6. Installing useful Pacman utilities..."
sudo pacman -S --noconfirm --needed yay pacman-contrib reflector

# 8. Optimize mirrors with Reflector
echo "7. Optimizing mirrors with Reflector..."
read -p "Do you want to optimize mirrors with Reflector? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Optimizing mirrors..."
    # Backup current mirrorlist
    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    
    # Use Reflector to get fastest 20 mirrors, sorted by speed, updated in the last 12 hours
    sudo reflector --country 'United States' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --number 20
    
    echo "Mirror optimization completed."
else
    echo "Skipping mirror optimization."
fi

echo ""

# 9. Show optimized Pacman configuration
echo "8. Optimized Pacman configuration:"
cat /etc/pacman.conf | grep -v '^#\|^$'
echo ""

# 10. Update system
echo "9. Updating system to latest packages..."
echo "This may take a while. Do you want to continue? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -Syu --noconfirm
fi

# 11. Enable Pacman hook for cache cleanup
echo "10. Setting up automatic cache cleanup hook..."

# Create cache cleanup hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/clean_cache.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning pacman cache...
When = PostTransaction
Exec = /usr/bin/paccache -r
EOF

echo "Automatic cache cleanup hook created."
echo ""

# 12. Final recommendations
echo "11. Pacman optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- Enabled color output"
echo "- Increased parallel downloads to 10"
echo "- Enabled ILoveCandy animation"
echo "- Enabled multilib repository"
echo "- Installed yay for AUR support"
echo "- Installed pacman-contrib for paccache"
echo "- Installed reflector for mirror optimization"
echo "- Set up automatic cache cleanup hook"
echo ""
echo "Recommended commands:"
echo "- Update system: sudo pacman -Syu"
echo "- Search package: pacman -Ss <package>"
echo "- Install package: sudo pacman -S <package>"
echo "- Remove package: sudo pacman -Rns <package>"
echo "- Clean cache: paccache -r"
echo "- Optimize mirrors: sudo reflector --country 'YourCountry' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --number 20"
echo "- Search AUR: yay -Ss <package>"
echo "- Install AUR: yay -S <package>"