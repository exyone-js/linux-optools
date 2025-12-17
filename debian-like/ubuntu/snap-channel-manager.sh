#!/bin/bash

# Snap Channel Management Script for Ubuntu

set -e

echo "===================================="
echo "       SNAP CHANNEL MANAGEMENT       "
echo "===================================="
echo ""

# Function to check if snap is installed
check_snap_installed() {
    if ! command -v snap &> /dev/null; then
        echo "Error: snap is not installed. This script is for systems with snap installed."
        exit 1
    fi
}

# Function to show current channel information
show_channel_info() {
    echo "1. Current Snap Channel Information:"
    echo "===================================="
    
    # Get list of installed snaps with channel info
    echo "Name                      Version          Rev    Tracking  Publisher   Notes"
    echo "------------------------------------------------------------"
    snap list | while read -r name version rev tracking publisher notes; do
        if [ "$name" != "Name" ]; then
            printf "%-25s %-15s %-5s %-9s %-12s %s\n" "$name" "$version" "$rev" "$tracking" "$publisher" "$notes"
        fi
    done
    echo ""
}

# Function to list available channels for a snap
list_available_channels() {
    read -p "Enter snap name to list channels: " snap_name
    
    echo -e "\nAvailable channels for $snap_name:"
    echo "===================================="
    snap info "$snap_name" | grep -A 20 "channels:" || echo "No channels information found for $snap_name"
    echo ""
}

# Function to change snap channel
change_snap_channel() {
    read -p "Enter snap name to change channel: " snap_name
    
    # Show current channel
    current_channel=$(snap info "$snap_name" | grep -E "^tracking:" | awk '{print $2}' || echo "Unknown")
    echo "Current channel for $snap_name: $current_channel"
    
    # List available channels
    echo -e "\nAvailable channels:"
    snap info "$snap_name" | grep -A 20 "channels:" || echo "No channels information found"
    
    read -p "Enter new channel (e.g., stable, beta, edge): " new_channel
    
    echo -e "\nChanging $snap_name from $current_channel to $new_channel..."
    sudo snap refresh "$snap_name" --channel="$new_channel"
    
    echo -e "\nChannel change completed!"
    echo "New channel for $snap_name: $(snap info "$snap_name" | grep -E "^tracking:" | awk '{print $2}')"
    echo ""
}

# Function to revert snap to previous revision/channel
revert_snap() {
    read -p "Enter snap name to revert: " snap_name
    
    echo "Reverting $snap_name to previous revision..."
    sudo snap revert "$snap_name"
    
    echo -e "\nRevert completed!"
    echo "Current channel for $snap_name: $(snap info "$snap_name" | grep -E "^tracking:" | awk '{print $2}')"
    echo ""
}

# Function to set all snaps to stable channel
set_all_to_stable() {
    echo "Setting all snaps to stable channel..."
    echo ""
    
    # Get list of installed snaps
    snap_apps=$(snap list | awk 'NR>1 {print $1}')
    
    for app in $snap_apps; do
        # Skip system snaps
        if [[ "$app" =~ ^(core|core18|core20|core22|core24|snapd|bare)$ ]]; then
            echo "Skipping system snap: $app"
            continue
        fi
        
        current_channel=$(snap info "$app" | grep -E "^tracking:" | awk '{print $2}' || echo "Unknown")
        
        if [ "$current_channel" != "stable" ]; then
            echo "Changing $app from $current_channel to stable..."
            sudo snap refresh "$app" --channel="stable" 2>/dev/null || echo "Failed to change channel for $app"
        else
            echo "$app is already on stable channel"
        fi
    done
    
    echo -e "\nAll snaps processed!"
    echo ""
}

# Main menu
main_menu() {
    while true; do
        echo "===================================="
        echo "         CHANNEL MANAGER MENU        "
        echo "===================================="
        echo ""
        echo "1. Show current channel information"
        echo "2. List available channels for a snap"
        echo "3. Change channel for a snap"
        echo "4. Revert snap to previous revision"
        echo "5. Set all snaps to stable channel"
        echo "6. Exit"
        echo ""
        
        read -p "Enter your choice (1-6): " channel_choice
        echo ""
        
        case $channel_choice in
            1)
                show_channel_info
                ;;
            2)
                list_available_channels
                ;;
            3)
                change_snap_channel
                ;;
            4)
                revert_snap
                ;;
            5)
                set_all_to_stable
                ;;
            6)
                echo "Exiting snap channel manager..."
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
main_menu