#!/bin/bash

# Linux.optools Common Function Library
# Version: 1.0.0
# Last Updated: 2025-12-17
# Description: Common functions for all optimization scripts

# -----------------------------------------------------------------------------
# Configuration Variables
# -----------------------------------------------------------------------------

# Logging settings
LOG_FILE="/var/log/optools.log"
LOG_LEVEL="info"  # debug, info, warn, error

# Backup settings
BACKUP_DIR="/var/backup/optools"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"
MAX_BACKUPS=10

# Script information
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0.0"

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

# Log messages with different severity levels
log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date +%Y-%m-%d_%H:%M:%S)"
    
    # Check if log level is enabled
    case "$level" in
        debug) [ "$LOG_LEVEL" != "debug" ] && return 0 ;;
        info) [ "$LOG_LEVEL" = "error" -o "$LOG_LEVEL" = "warn" ] && return 0 ;;
        warn) [ "$LOG_LEVEL" = "error" ] && return 0 ;;
    esac
    
    # Format log message
    local log_message="$timestamp [$level] $SCRIPT_NAME: $message"
    
    # Print to console
    case "$level" in
        debug) echo -e "\033[0;36m$log_message\033[0m" ;;
        info) echo -e "\033[0;32m$log_message\033[0m" ;;
        warn) echo -e "\033[0;33m$log_message\033[0m" ;;
        error) echo -e "\033[0;31m$log_message\033[0m" ;;
    esac
    
    # Write to log file
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    echo "$log_message" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Debug logging
log_debug() {
    log "debug" "$1"
}

# Info logging
log_info() {
    log "info" "$1"
}

# Warning logging
log_warn() {
    log "warn" "$1"
}

# Error logging
log_error() {
    log "error" "$1"
}

# -----------------------------------------------------------------------------
# Error Handling Functions
# -----------------------------------------------------------------------------

# Set error trap
set_error_trap() {
    trap 'handle_error $? $LINENO' ERR
}

# Error handler
handle_error() {
    local exit_code="$1"
    local line_no="$2"
    
    log_error "Error occurred in $SCRIPT_NAME at line $line_no: Exit code $exit_code"
    log_error "Last command: ${BASH_COMMAND}"
    
    # Ask user if they want to continue
    if [ "$EXIT_ON_ERROR" != "true" ]; then
        read -p "Continue execution? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Execution aborted by user"
            exit $exit_code
        fi
    else
        log_info "Exiting due to error"
        exit $exit_code
    fi
}

# Exit with error
abort() {
    local message="$1"
    local exit_code="${2:-1}"
    
    log_error "$message"
    log_info "Script execution aborted"
    exit $exit_code
}

# Check if command succeeded
check_success() {
    local exit_code="$1"
    local success_msg="$2"
    local error_msg="$3"
    
    if [ $exit_code -eq 0 ]; then
        log_info "$success_msg"
        return 0
    else
        log_error "$error_msg"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Backup and Restore Functions
# -----------------------------------------------------------------------------

# Initialize backup directory
init_backup() {
    sudo mkdir -p "$BACKUP_DIR"
    log_info "Backup directory initialized: $BACKUP_DIR"
}

# Create backup of a file or directory
backup() {
    local source="$1"
    local description="${2:-$source}"
    
    if [ ! -e "$source" ]; then
        log_debug "$source does not exist, skipping backup"
        return 0
    fi
    
    init_backup
    
    local backup_name="$(basename "$source")"
    local backup_path="$BACKUP_DIR/$backup_name.$BACKUP_SUFFIX"
    
    log_info "Creating backup of $description to $backup_path"
    
    if [ -d "$source" ]; then
        sudo tar -czf "$backup_path.tar.gz" -C "$(dirname "$source")" "$(basename "$source")" 2>/dev/null
    else
        sudo cp "$source" "$backup_path" 2>/dev/null
    fi
    
    check_success $? "Backup of $description created successfully" "Failed to create backup of $description"
    
    # Clean up old backups
    cleanup_old_backups "$source"
    
    return 0
}

# Restore from backup
restore_backup() {
    local source="$1"
    local backup_file="$2"
    local description="${3:-$source}"
    
    if [ ! -e "$backup_file" ]; then
        log_error "Backup file $backup_file does not exist"
        return 1
    fi
    
    log_info "Restoring $description from $backup_file"
    
    if [[ "$backup_file" == *.tar.gz ]]; then
        local backup_name="$(basename "$backup_file" .tar.gz)"
        sudo tar -xzf "$backup_file" -C "$(dirname "$source")" 2>/dev/null
    else
        sudo cp "$backup_file" "$source" 2>/dev/null
    fi
    
    check_success $? "Restored $description from backup" "Failed to restore $description from backup"
    return 0
}

# Clean up old backups
cleanup_old_backups() {
    local source="$1"
    local backup_name="$(basename "$source")"
    
    # Count existing backups
    local backup_count=$(sudo ls -1 "$BACKUP_DIR/$backup_name.*" 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        log_info "Cleaning up old backups for $source"
        # Delete oldest backups, keep only the newest MAX_BACKUPS
        sudo ls -1t "$BACKUP_DIR/$backup_name.*" 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | sudo xargs -r rm
    fi
}

# List available backups for a file/directory
list_backups() {
    local source="$1"
    local backup_name="$(basename "$source")"
    
    log_info "Available backups for $source:"
    sudo ls -la "$BACKUP_DIR/$backup_name.*" 2>/dev/null || log_info "No backups found"
}

# -----------------------------------------------------------------------------
# System Information Functions
# -----------------------------------------------------------------------------

# Detect Linux distribution
detect_distribution() {
    if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        DISTRO_NAME="$NAME"
    elif [ -f "/etc/redhat-release" ]; then
        DISTRO="rhel"
        DISTRO_VERSION=$(grep -oE "[0-9]+\.[0-9]+" /etc/redhat-release)
        DISTRO_NAME="Red Hat Enterprise Linux"
    elif [ -f "/etc/debian_version" ]; then
        DISTRO="debian"
        DISTRO_VERSION=$(cat /etc/debian_version)
        DISTRO_NAME="Debian"
    else
        DISTRO="unknown"
        DISTRO_VERSION="unknown"
        DISTRO_NAME="Unknown Linux Distribution"
    fi
    
    log_debug "Detected distribution: $DISTRO_NAME ($DISTRO $DISTRO_VERSION)"
}

# Detect desktop environment
detect_desktop() {
    DESKTOP_ENV="$XDG_CURRENT_DESKTOP"
    
    if [ -z "$DESKTOP_ENV" ]; then
        if command -v gnome-session &> /dev/null; then
            DESKTOP_ENV="GNOME"
        elif command -v startkde &> /dev/null; then
            DESKTOP_ENV="KDE"
        elif command -v startxfce4 &> /dev/null; then
            DESKTOP_ENV="XFCE"
        elif command -v i3 &> /dev/null; then
            DESKTOP_ENV="i3"
        else
            DESKTOP_ENV="none"
        fi
    fi
    
    log_debug "Detected desktop environment: $DESKTOP_ENV"
}

# Detect hardware type (laptop/desktop)
detect_hardware() {
    if grep -q "^DMI:.*[Ll]aptop" /sys/class/dmi/id/chassis_type 2>/dev/null || \
       grep -q "^Chassis\s*Type:\s*10" /proc/cpuinfo 2>/dev/null || \
       [ -d "/proc/acpi/battery" ] || \
       [ -d "/sys/class/power_supply/BAT"* ]; then
        HARDWARE_TYPE="laptop"
    else
        HARDWARE_TYPE="desktop"
    fi
    
    log_debug "Detected hardware type: $HARDWARE_TYPE"
}

# -----------------------------------------------------------------------------
# Package Management Functions
# -----------------------------------------------------------------------------

# Update package lists
update_packages() {
    log_info "Updating package lists..."
    
    case "$DISTRO" in
        debian|ubuntu|linuxmint) sudo apt update ;;
        fedora|centos|rocky|rhel) sudo dnf update -y ;;
        arch|manjaro) sudo pacman -Sy --noconfirm ;;
        opensuse*) sudo zypper refresh ;;
        *) log_warn "Unknown distribution, skipping package update" ; return 1 ;;
    esac
    
    check_success $? "Package lists updated" "Failed to update package lists"
}

# Install packages
install_packages() {
    local packages="$@"
    log_info "Installing packages: $packages"
    
    case "$DISTRO" in
        debian|ubuntu|linuxmint) sudo apt install -y $packages ;;
        fedora|centos|rocky|rhel) sudo dnf install -y $packages ;;
        arch|manjaro) sudo pacman -S --noconfirm --needed $packages ;;
        opensuse*) sudo zypper install -y $packages ;;
        *) log_warn "Unknown distribution, skipping package installation" ; return 1 ;;
    esac
    
    check_success $? "Packages installed successfully" "Failed to install packages"
}

# Remove packages
remove_packages() {
    local packages="$@"
    log_info "Removing packages: $packages"
    
    case "$DISTRO" in
        debian|ubuntu|linuxmint) sudo apt remove -y $packages ;;
        fedora|centos|rocky|rhel) sudo dnf remove -y $packages ;;
        arch|manjaro) sudo pacman -Rns --noconfirm $packages ;;
        opensuse*) sudo zypper remove -y $packages ;;
        *) log_warn "Unknown distribution, skipping package removal" ; return 1 ;;
    esac
    
    check_success $? "Packages removed successfully" "Failed to remove packages"
}

# -----------------------------------------------------------------------------
# Service Management Functions
# -----------------------------------------------------------------------------

# Enable and start a service
enable_service() {
    local service="$1"
    log_info "Enabling and starting service: $service"
    
    sudo systemctl enable --now "$service"
    check_success $? "Service $service enabled and started" "Failed to enable/start service $service"
}

# Disable and stop a service
disable_service() {
    local service="$1"
    log_info "Disabling and stopping service: $service"
    
    sudo systemctl disable --now "$service"
    check_success $? "Service $service disabled and stopped" "Failed to disable/stop service $service"
}

# Restart a service
restart_service() {
    local service="$1"
    log_info "Restarting service: $service"
    
    sudo systemctl restart "$service"
    check_success $? "Service $service restarted" "Failed to restart service $service"
}

# Check service status
check_service() {
    local service="$1"
    log_info "Checking status of service: $service"
    
    systemctl status "$service" --no-pager
    return $?
}

# -----------------------------------------------------------------------------
# File Manipulation Functions
# -----------------------------------------------------------------------------

# Create a directory if it doesn't exist
create_dir() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        log_info "Creating directory: $dir"
        sudo mkdir -p "$dir"
        check_success $? "Directory created: $dir" "Failed to create directory: $dir"
    else
        log_debug "Directory already exists: $dir"
    fi
}

# Create a file if it doesn't exist
create_file() {
    local file="$1"
    local content="${2:-}"
    
    if [ ! -f "$file" ]; then
        log_info "Creating file: $file"
        sudo mkdir -p "$(dirname "$file")"
        echo "$content" | sudo tee "$file" > /dev/null
        check_success $? "File created: $file" "Failed to create file: $file"
    else
        log_debug "File already exists: $file"
    fi
}

# Append to file
append_to_file() {
    local file="$1"
    local content="$2"
    
    log_info "Appending to file: $file"
    echo "$content" | sudo tee -a "$file" > /dev/null
    check_success $? "Content appended to $file" "Failed to append to $file"
}

# Replace in file (sed)
replace_in_file() {
    local file="$1"
    local old_pattern="$2"
    local new_pattern="$3"
    
    log_info "Replacing in file: $file"
    log_debug "Pattern: '$old_pattern' -> '$new_pattern'"
    
    sudo sed -i "s/$old_pattern/$new_pattern/g" "$file"
    check_success $? "Replacement in $file completed" "Failed to replace in $file"
}

# -----------------------------------------------------------------------------
# User Interaction Functions
# -----------------------------------------------------------------------------

# Ask user for confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        prompt="$prompt (Y/n): "
    else
        prompt="$prompt (y/N): "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ -z $REPLY ]]; then
        REPLY="$default"
    fi
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Show progress bar
show_progress() {
    local progress="$1"  # 0-100
    local width=50
    local filled=$((progress * width / 100))
    local empty=$((width - filled))
    
    printf "\r[%${filled}s%${empty}s] %d%%" "$(printf '#%.0s' $(seq 1 $filled))" "" "$progress"
    
    if [ $progress -eq 100 ]; then
        echo
    fi
}

# -----------------------------------------------------------------------------
# Script Initialization Functions
# -----------------------------------------------------------------------------

# Initialize script environment
init_script() {
    # Set error trap
    set_error_trap
    
    # Detect system information
    detect_distribution
    detect_desktop
    detect_hardware
    
    # Create temporary directory for script
    TMP_DIR=$(mktemp -d /tmp/optools.XXXXXX)
    trap "cleanup" EXIT
    
    log_info "Script initialized: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "System: $DISTRO_NAME $DISTRO_VERSION ($HARDWARE_TYPE)"
    log_info "Desktop: $DESKTOP_ENV"
}

# Cleanup temporary files
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        log_debug "Cleaning up temporary directory: $TMP_DIR"
        sudo rm -rf "$TMP_DIR"
    fi
    
    log_info "Script cleanup completed"
}

# Show script header
show_header() {
    local title="$1"
    local version="${2:-$SCRIPT_VERSION}"
    
    echo "=================================================="
    echo "$title"
    echo "Version: $version"
    echo "=================================================="
    echo
}

# Show script footer
show_footer() {
    local success="$1"
    
    echo
    echo "=================================================="
    if [ "$success" = "true" ]; then
        echo "Script completed successfully!"
    else
        echo "Script completed with errors!"
    fi
    echo "=================================================="
}

# -----------------------------------------------------------------------------
# End of Common Function Library
# -----------------------------------------------------------------------------
