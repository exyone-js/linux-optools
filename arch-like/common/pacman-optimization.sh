#!/bin/bash

# Pacman Package Manager Optimization for Arch-like Systems
# Version: 1.1.0
# Last Updated: 2025-12-17
# Description: Optimizes Pacman package manager configuration for better performance and usability

# -----------------------------------------------------------------------------
# Changelog
# -----------------------------------------------------------------------------
# 1.1.0 (2025-12-17):
#   - Updated to use common function library
#   - Added improved error handling and logging
#   - Added standardized backup mechanism
#   - Improved user interaction
#   - Added script cleanup functionality
#
# 1.0.0 (2025-12-01):
#   - Initial version
#   - Basic Pacman configuration optimization
#   - Added parallel downloads, color output, and ILoveCandy
#   - Added AUR support with yay
#   - Added mirror optimization with reflector

# -----------------------------------------------------------------------------

# Source the common function library
SCRIPT_DIR="$(dirname "$0")"
COMMON_LIB="$SCRIPT_DIR/../../common/common-lib.sh"

if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    echo "Error: Common function library not found at $COMMON_LIB"
    exit 1
fi

# Script-specific variables
SCRIPT_VERSION="1.1.0"
SCRIPT_NAME="$(basename "$0")"

# -----------------------------------------------------------------------------

# Initialize script
init_script

# Show script header
show_header "Pacman Package Manager Optimization"

# -----------------------------------------------------------------------------
# Main script execution
# -----------------------------------------------------------------------------

# Check if Pacman is installed
if ! command -v pacman &> /dev/null; then
    abort "Error: pacman is not installed. This script is for systems with Pacman package manager." 1
fi

# Show current Pacman configuration
log_info "Current Pacman configuration:"
cat /etc/pacman.conf | grep -v '^#\|^$' || log_warn "Pacman configuration file not found"
echo ""

# Backup current Pacman configuration
backup "/etc/pacman.conf" "Pacman configuration"

# Optimize Pacman configuration
log_info "Optimizing Pacman configuration..."

# Enable color output
replace_in_file "/etc/pacman.conf" "^#Color" "Color"

# Enable parallel downloads (set to 10)
replace_in_file "/etc/pacman.conf" "^#ParallelDownloads = 5" "ParallelDownloads = 10"

# Enable ILoveCandy (just for fun, optional)
log_info "Enabling ILoveCandy animation..."
replace_in_file "/etc/pacman.conf" "^#ILoveCandy" "ILoveCandy"

# Enable multilib repository
log_info "Enabling multilib repository..."
replace_in_file "/etc/pacman.conf" "\[multilib\]\n#Include" "\[multilib\]\nInclude"

# Add additional repositories if needed
if confirm "Do you want to add Chaotic-AUR repository?" "n"; then
    # Add Chaotic-AUR repository
    log_info "Adding Chaotic-AUR repository..."
    sudo pacman-key --recv-key FBA4E0A2871F16537A48C2FEB6430107F4A319E8
    check_success $? "Received Chaotic-AUR GPG key" "Failed to receive Chaotic-AUR GPG key"
    
    sudo pacman-key --lsign-key FBA4E0A2871F16537A48C2FEB6430107F4A319E8
    check_success $? "Signed Chaotic-AUR GPG key" "Failed to sign Chaotic-AUR GPG key"
    
    append_to_file "/etc/pacman.conf" "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist"
    
    # Install chaotic-mirrorlist
    log_info "Installing chaotic-mirrorlist..."
    install_packages chaotic-mirrorlist || log_warn "Failed to install chaotic-mirrorlist. Please install manually."
fi

# Update Pacman databases
log_info "Updating Pacman databases..."
sudo pacman -Sy
check_success $? "Pacman databases updated" "Failed to update Pacman databases"

# Clean Pacman cache
log_info "Cleaning Pacman cache..."
echo "Available cache cleanup options:"
echo "1. Remove all cached packages except the latest version"
echo "2. Remove all cached packages"
echo "3. Skip cache cleanup"
echo ""

read -p "Enter your choice (1-3): " cache_choice

case $cache_choice in
    1)
        log_info "Removing old cached packages..."
        paccache -r
        check_success $? "Removed old cached packages" "Failed to remove old cached packages"
        ;;
    2)
        log_info "Removing all cached packages..."
        paccache -rk0
        check_success $? "Removed all cached packages" "Failed to remove all cached packages"
        ;;
    3)
        log_info "Skipping cache cleanup."
        ;;
    *)
        log_warn "Invalid choice. Skipping cache cleanup."
        ;;
esac
echo ""

# Install useful Pacman utilities
log_info "Installing useful Pacman utilities..."
install_packages yay pacman-contrib reflector

# Optimize mirrors with Reflector
if confirm "Do you want to optimize mirrors with Reflector?" "n"; then
    log_info "Optimizing mirrors..."
    # Backup current mirrorlist
    backup "/etc/pacman.d/mirrorlist" "Pacman mirrorlist"
    
    # Use Reflector to get fastest 20 mirrors, sorted by speed, updated in the last 12 hours
    sudo reflector --country 'United States' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist --number 20
    check_success $? "Mirror optimization completed" "Failed to optimize mirrors"
else
    log_info "Skipping mirror optimization."
fi

echo ""

# Show optimized Pacman configuration
log_info "Optimized Pacman configuration:"
cat /etc/pacman.conf | grep -v '^#\|^$'
echo ""

# Update system
if confirm "Update system to latest packages? This may take a while." "n"; then
    log_info "Updating system to latest packages..."
    sudo pacman -Syu --noconfirm
    check_success $? "System updated successfully" "Failed to update system"
fi

# Enable Pacman hook for cache cleanup
log_info "Setting up automatic cache cleanup hook..."

# Create cache cleanup hook
create_dir "/etc/pacman.d/hooks"

create_file "/etc/pacman.d/hooks/clean_cache.hook" "[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning pacman cache...
When = PostTransaction
Exec = /usr/bin/paccache -r"

log_info "Automatic cache cleanup hook created."
echo ""

# Show final optimization summary
show_footer "true"

log_info "Key optimizations applied:"
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

# -----------------------------------------------------------------------------
# End of script
# -----------------------------------------------------------------------------
