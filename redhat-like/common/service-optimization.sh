#!/bin/bash

# System Service Optimization for Red Hat-like Systems

set -e

echo "Starting system service optimization..."

# 1. Show system boot time
echo "1. Current system boot time:"
 systemd-analyze
 echo ""

# 2. Show top services by boot time
echo "2. Top services by boot time:"
 systemd-analyze blame | head -20
 echo ""

# 3. Show failed services
echo "3. Failed services:"
 systemctl --failed
 echo ""

# 4. List all enabled services
echo "4. All enabled services:"
 systemctl list-unit-files --state=enabled | head -30
echo "(Only showing first 30 services)"
echo ""

# 5. Define list of services to consider disabling
echo "5. Services that can be considered for disabling:"
echo "=================================================="
cat <<EOF
# Desktop environment services (if not needed)
- bluetooth.service
- cups.service
- avahi-daemon.service
- rtkit-daemon.service
- colord.service
- geoclue.service
- pulseaudio.service (if using pipewire)
- pipewire.service (if using pulseaudio)

# Network services (if not needed)
- nm-cloud-setup.service
- teamd.service
- wpa_supplicant.service (if using wired network)

# Printing services (if not needed)
- cups-browsed.service
- cups.service

# Virtualization services (if not needed)
- libvirtd.service
- virtlockd.service
- virtlogd.service

# Container services (if not needed)
- docker.service
- containerd.service
- podman.service

# Storage services (if not needed)
- iscsid.service
- iscsiuio.service
- multipathd.service

# Remote access services (if not needed)
- sshd.service (only if you don't need remote access)
- telnet.service

# Monitoring services (if not needed)
- cockpit.service
- tuned.service
EOF

echo ""

# 6. Interactive service management
echo "6. Interactive service management:"
echo "=================================================="
echo "Available options:"
echo "1. Disable a specific service"
echo "2. Enable a specific service"
echo "3. Show service status"
echo "4. List services by resource usage"
echo "5. Exit service management"
echo ""

while true; do
    read -p "Enter your choice (1-5): " service_choice
    echo ""
    
    case $service_choice in
        1)
            read -p "Enter service name to disable: " service_name
            echo "Disabling $service_name..."
            sudo systemctl disable --now "$service_name"
            echo "$service_name has been disabled and stopped."
            echo ""
            ;;
        2)
            read -p "Enter service name to enable: " service_name
            echo "Enabling $service_name..."
            sudo systemctl enable --now "$service_name"
            echo "$service_name has been enabled and started."
            echo ""
            ;;
        3)
            read -p "Enter service name to check status: " service_name
            echo "Status of $service_name:"
            systemctl status "$service_name" --no-pager
            echo ""
            ;;
        4)
            echo "Top services by memory usage:"
            echo "(Requires systemd-cgtop, available in systemd-container package)"
            if command -v systemd-cgtop &> /dev/null; then
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            else
                echo "Installing systemd-container package for systemd-cgtop..."
                sudo dnf install -y systemd-container
                systemd-cgtop --cpu --memory --state=running --order=cpu --iterations=1
            fi
            echo ""
            ;;
        5)
            echo "Exiting service management..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1-5."
            echo ""
            ;;
    esac
done

# 7. Apply tuned profile for optimal performance
echo "7. Tuned profile optimization:"
echo "Available tuned profiles:"
tuned-adm list 2>/dev/null || echo "tuned-adm not available"

if command -v tuned-adm &> /dev/null; then
    current_profile=$(tuned-adm active | grep -E "^Current active profile: " | cut -d: -f2 | tr -d ' ') 2>/dev/null || true
    echo "Current active profile: $current_profile"
    
    read -p "Do you want to apply a tuned profile? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Available profiles for selection:"
        tuned-adm list | grep -E "^\s*\[\s*\*\s*\]" -A 20 || true
        read -p "Enter profile name: " profile_name
        echo "Applying tuned profile $profile_name..."
        sudo tuned-adm profile "$profile_name"
        echo "Profile $profile_name has been applied."
    fi
fi

echo ""
echo "System service optimization completed!"
echo "Key recommendations:"
echo "  - Review the list of enabled services and disable unnecessary ones"
echo "  - Use 'systemctl disable --now <service>' to disable services"
echo "  - Use 'systemctl enable --now <service>' to enable services"
echo "  - Consider applying an appropriate tuned profile for your system"
echo "  - Reboot your system to see the full effect of service changes"
