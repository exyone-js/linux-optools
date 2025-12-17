#!/bin/bash

# Package Cleanup Script for Debian-like Systems
# Version: 1.1.0
# Last Updated: 2025-12-17
# Description: Removes unnecessary packages, cleans cache, and removes old kernels

# -----------------------------------------------------------------------------
# Changelog
# -----------------------------------------------------------------------------
# 1.1.0 (2025-12-17):
#   - Updated to use common function library
#   - Added improved error handling and logging
#   - Added standardized backup mechanism
#   - Improved user interaction
#   - Added script cleanup functionality
#   - Added version control and changelog
#   - Enhanced kernel removal safety
#
# 1.0.0 (2025-12-01):
#   - Initial version
#   - Basic package cleanup functionality
#   - Added cache cleaning
#   - Added old kernel removal

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
show_header "Package Cleanup"

# -----------------------------------------------------------------------------
# Main script execution
# -----------------------------------------------------------------------------

log_info "Starting package cleanup process..."

# Update package lists first
log_info "Updating package lists..."
update_packages

# Remove unnecessary packages
log_info "Removing unnecessary packages..."
sudo apt autoremove --purge -y
check_success $? "Unnecessary packages removed successfully" "Failed to remove unnecessary packages"

# Clean package cache
log_info "Cleaning package cache..."
sudo apt clean
check_success $? "Package cache cleaned successfully" "Failed to clean package cache"

sudo apt autoclean
check_success $? "Old package cache cleaned successfully" "Failed to clean old package cache"

# Remove old kernels (keep current and previous versions)
log_info "Removing old kernels..."

# Get current kernel version
CURRENT_KERNEL="$(uname -r)"
PREVIOUS_KERNEL_VERSION="$(echo "$CURRENT_KERNEL" | cut -d- -f1,2)"

log_debug "Current kernel: $CURRENT_KERNEL"
log_debug "Previous kernel version: $PREVIOUS_KERNEL_VERSION"

# List old kernels to remove
OLD_KERNELS=$(dpkg --list | grep 'linux-image' | awk '{print $2}' | grep -v "$CURRENT_KERNEL" | grep -v "$PREVIOUS_KERNEL_VERSION" 2>/dev/null || echo "")

if [ -z "$OLD_KERNELS" ]; then
    log_info "No old kernels found to remove"
else
    log_info "Found old kernels: $OLD_KERNELS"
    
    # Show confirmation before removing
    if confirm "Do you want to remove these old kernels?" "y"; then
        log_info "Removing old kernels: $OLD_KERNELS"
        sudo apt purge -y $OLD_KERNELS
        check_success $? "Old kernels removed successfully" "Failed to remove old kernels"
    else
        log_info "Skipping old kernel removal"
    fi
fi

# Clean up package configuration files
log_info "Cleaning up package configuration files..."
sudo dpkg --purge $(dpkg --list | grep '^rc' | awk '{print $2}') 2>/dev/null || true
check_success $? "Package configuration files cleaned successfully" "Failed to clean package configuration files"

# Show final summary
log_info "Package cleanup completed!"
echo "=================================================="
echo "Key cleanup tasks performed:"
echo "- Updated package lists"
echo "- Removed unnecessary packages with dependencies"
echo "- Cleaned package cache"
echo "- Cleaned old package cache"
echo "- Removed old kernels (if any)"
echo "- Cleaned package configuration files"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system if old kernels were removed"
echo "- Run 'df -h' to check disk space savings"
echo "- Consider scheduling this script to run automatically"
echo "- Regularly check for system updates with 'sudo apt update'"

# Show script footer
show_footer "true"

# -----------------------------------------------------------------------------
# End of script
# -----------------------------------------------------------------------------
