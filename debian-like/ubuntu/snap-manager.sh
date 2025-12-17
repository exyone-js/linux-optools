#!/bin/bash

# Comprehensive Snap Management Script for Ubuntu

set -e

echo "===================================="
echo "       SNAP MANAGEMENT TOOL         "
echo "===================================="
echo ""

# Function to check if snap is installed
check_snap_installed() {
    if ! command -v snap &> /dev/null; then
        echo "Error: snap is not installed. This script is for systems with snap installed."
        exit 1
    fi
}

# Function to show snap information
show_snap_info() {
    echo "1. Snap System Information:"
    echo "===================================="
    snap version
    echo ""
    
    echo "2. Snap Refresh Settings:"
    echo "===================================="
    snap get system refresh
    echo ""
    
    echo "3. Installed Snap Applications:"
    echo "===================================="
    snap list
    echo ""
    
    echo "4. Snap Disk Usage:"
    echo "===================================="
    du -sh /var/lib/snapd/ 2>/dev/null || true
    du -sh ~/snap/ 2>/dev/null || true
    echo ""
    
    echo "5. Snap Mount Information:"
    echo "===================================="
    mount | grep snap || echo "No snap mounts found"
    echo ""
}

# Function to manage snap refreshes
manage_snap_refreshes() {
    echo "===================================="
    echo "       SNAP REFRESH MANAGEMENT      "
    echo "===================================="
    echo ""
    
    echo "Current refresh settings:"
    snap get system refresh
    echo ""
    
    echo "Available refresh commands:"
    echo "1. Set refresh timer"
    echo "2. Hold snap refreshes"
    echo "3. Unhold snap refreshes"
    echo "4. Manual refresh all snaps"
    echo "5. Manual refresh specific snap"
    echo "6. Back to main menu"
    echo ""
    
    read -p "Enter your choice (1-6): " refresh_choice
    
    case $refresh_choice in
        1)
            read -p "Enter refresh timer (e.g., 02:00-04:00): " refresh_timer
            sudo snap set system refresh.timer="$refresh_timer"
            echo "Refresh timer set to $refresh_timer"
            ;;
        2)
            read -p "Enter hold duration (e.g., 7d, 14d, 30d): " hold_duration
            sudo snap set system refresh.hold="$hold_duration"
            echo "Snap refreshes held for $hold_duration"
            ;;
        3)
            sudo snap set system refresh.hold=""
            echo "Snap refreshes unheld"
            ;;
        4)
            echo "Refreshing all snaps..."
            sudo snap refresh
            ;;
        5)
            read -p "Enter snap name to refresh: " snap_name
            sudo snap refresh "$snap_name"
            ;;
        6)
            return
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    echo ""
}

# Function to clean snap resources
clean_snap_resources() {
    echo "===================================="
    echo "       SNAP CLEANUP MANAGEMENT      "
    echo "===================================="
    echo ""
    
    echo "Available cleanup commands:"
    echo "1. Remove disabled snap revisions"
    echo "2. Clean snap cache"
    echo "3. Clean all snap resources"
    echo "4. Back to main menu"
    echo ""
    
    read -p "Enter your choice (1-4): " cleanup_choice
    
    case $cleanup_choice in
        1)
            echo "Removing disabled snap revisions..."
            sudo snap list --all | grep disabled | awk '{print $1, $3}' | while read snapname revision; do
                echo "Removing $snapname revision $revision..."
                sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
            done
            echo "Disabled revisions removed"
            ;;
        2)
            echo "Cleaning snap cache..."
            sudo rm -rf /var/lib/snapd/cache/* 2>/dev/null || true
            echo "Snap cache cleaned"
            ;;
        3)
            echo "Cleaning all snap resources..."
            # Remove disabled revisions
            sudo snap list --all | grep disabled | awk '{print $1, $3}' | while read snapname revision; do
                sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
            done
            # Clean cache
            sudo rm -rf /var/lib/snapd/cache/* 2>/dev/null || true
            echo "All snap resources cleaned"
            ;;
        4)
            return
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    echo ""
}

# Function to check snap health
check_snap_health() {
    echo "===================================="
    echo "         SNAP HEALTH CHECK           "
    echo "===================================="
    echo ""
    
    echo "Checking snap service status..."
    sudo systemctl status snapd snapd.socket --no-pager
    echo ""
    
    echo "Checking snap mount points..."
    mount | grep snap || echo "No snap mounts found"
    echo ""
    
    echo "Checking snap app integrity..."
    snap list | awk 'NR>1 {print $1}' | while read snapname; do
        if ! snap check "$snapname" 2>/dev/null; then
            echo "✗ Integrity check failed for $snapname"
        else
            echo "✓ Integrity check passed for $snapname"
        fi
    done
    echo ""
}

# Function to manage snap permissions
manage_snap_permissions() {
    echo "===================================="
    echo "       SNAP PERMISSIONS MANAGEMENT   "
    echo "===================================="
    echo ""
    
    echo "Available permission commands:"
    echo "1. List all snap permissions"
    echo "2. List permissions for specific snap"
    echo "3. Connect snap interface"
    echo "4. Disconnect snap interface"
    echo "5. Back to main menu"
    echo ""
    
    read -p "Enter your choice (1-5): " perm_choice
    
    case $perm_choice in
        1)
            echo "Listing all snap permissions..."
            snap connections
            ;;
        2)
            read -p "Enter snap name: " snap_name
            echo "Listing permissions for $snap_name..."
            snap connections "$snap_name"
            ;;
        3)
            read -p "Enter snap interface to connect (e.g., snap:camera): " interface
            sudo snap connect "$interface"
            ;;
        4)
            read -p "Enter snap interface to disconnect (e.g., snap:camera): " interface
            sudo snap disconnect "$interface"
            ;;
        5)
            return
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    echo ""
}

# Main menu
main_menu() {
    while true; do
        echo "===================================="
        echo "         SNAP MANAGER MAIN MENU      "
        echo "===================================="
        echo ""
        echo "1. Show snap information"
        echo "2. Manage snap refreshes"
        echo "3. Clean snap resources"
        echo "4. Check snap health"
        echo "5. Manage snap permissions"
        echo "6. Exit"
        echo ""
        
        read -p "Enter your choice (1-6): " main_choice
        echo ""
        
        case $main_choice in
            1)
                show_snap_info
                ;;
            2)
                manage_snap_refreshes
                ;;
            3)
                clean_snap_resources
                ;;
            4)
                check_snap_health
                ;;
            5)
                manage_snap_permissions
                ;;
            6)
                echo "Exiting snap manager..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1-6."
                echo ""
                ;;
        esac
    done
}

# Main script execution
check_snap_installed
action="$1"

if [ -n "$action" ]; then
    # Run specific action
    case $action in
        info)
            show_snap_info
            ;;
        refresh)
            manage_snap_refreshes
            ;;
        clean)
            clean_snap_resources
            ;;
        health)
            check_snap_health
            ;;
        permissions)
            manage_snap_permissions
            ;;
        *)
            echo "Usage: $0 [info|refresh|clean|health|permissions]"
            echo "Without arguments, starts interactive menu"
            exit 1
            ;;
    esac
else
    # Start interactive menu
    main_menu
fi