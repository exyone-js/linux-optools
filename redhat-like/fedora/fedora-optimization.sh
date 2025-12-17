#!/bin/bash

# Fedora Specific Optimization Script

set -e

echo "Starting Fedora specific optimization..."

# 1. Show Fedora version
echo "1. Fedora version:"
 cat /etc/fedora-release
 echo ""

# 2. Update system to latest packages
echo "2. Updating system to latest packages..."
sudo dnf update -y
 echo ""

# 3. Enable DNF5 if available (Fedora 38+)
echo "3. Checking for DNF5 support..."
if command -v dnf5 &> /dev/null; then
    echo "DNF5 is available. Enabling DNF5 as default..."
    sudo dnf install -y dnf5
sudo alternatives --set dnf /usr/bin/dnf5
 echo "DNF5 has been set as default."
else
    echo "DNF5 is not available on this Fedora version."
fi
echo ""

# 4. Optimize Flatpak settings
echo "4. Optimizing Flatpak settings..."
if command -v flatpak &> /dev/null; then
    echo "Flatpak is installed. Optimizing settings..."
    
    # Install flatpak-plugin-system-helper for better integration
    sudo dnf install -y flatpak-plugin-system-helper 2>/dev/null || true
    
    # Clean old flatpak runtimes
    echo "Cleaning old Flatpak runtimes..."
    flatpak uninstall --unused -y
    
    # Set flatpak to use fastest mirror
    echo "Setting Flatpak to use fastest mirror..."
    flatpak remote-modify flathub --mirror-schema=https --mirror-host=https://flathub.org/repo/
    
    echo "Flatpak optimization completed."
else
    echo "Flatpak is not installed. Skipping Flatpak optimization."
fi
echo ""

# 5. Enable RPM Fusion repositories
echo "5. Enabling RPM Fusion repositories..."
echo "RPM Fusion provides additional packages not available in the official Fedora repositories."
read -p "Do you want to enable RPM Fusion repositories? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enabling RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    
    # Enable RPM Fusion tainted repos if needed
    read -p "Do you want to enable RPM Fusion tainted repositories? (y/N) " -n 1 -r
echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
    fi
    
    echo "RPM Fusion repositories enabled successfully."
fi
echo ""

# 6. Configure power management for laptops
echo "6. Configuring power management..."
if [[ $(dmidecode -s system-product-name) =~ "Laptop|Notebook" ]]; then
    echo "Laptop detected. Optimizing power management..."
    
    # Install power management tools
    sudo dnf install -y tlp powertop
    
    # Enable TLP
    sudo systemctl enable --now tlp
    
    # Run powertop auto-tune
    sudo powertop --auto-tune
    
    # Install thermald for thermal management
    sudo dnf install -y thermald
    sudo systemctl enable --now thermald
    
    echo "Power management optimization completed."
else
    echo "Desktop system detected. Skipping power management optimization."
fi
echo ""

# 7. Optimize Wayland settings (Fedora default)
echo "7. Optimizing Wayland settings..."
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "Wayland session detected. Optimizing Wayland settings..."
    
    # Install Wayland utilities
    sudo dnf install -y wayland-utils xwayland
    
    # Enable fractional scaling if supported (Fedora 36+)
    echo "Enabling fractional scaling support..."
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null || true
    
    echo "Wayland optimization completed."
else
    echo "X11 session detected. Skipping Wayland optimization."
fi
echo ""

# 8. Configure systemd-oomd (Out of Memory Daemon)
echo "8. Configuring systemd-oomd..."
echo "systemd-oomd provides better memory management and can prevent system freezes."
read -p "Do you want to enable and configure systemd-oomd? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enabling systemd-oomd..."
    sudo systemctl enable --now systemd-oomd
    
    # Configure systemd-oomd settings
    echo "Configuring systemd-oomd settings..."
    sudo tee -a /etc/systemd/oomd.conf.d/optimized.conf <<EOF
[OOM]
DefaultMemoryPressureDurationSec=30s
DefaultMemoryPressureLimit=60%
DefaultSwapUsageLimit=90%
EOF
    
    sudo systemctl restart systemd-oomd
    echo "systemd-oomd configuration completed."
fi
echo ""

# 9. Optimize for gaming (if needed)
echo "9. Gaming optimization options:"
echo "=================================================="
echo "Available gaming optimizations:"
echo "1. Install Steam and gaming packages"
echo "2. Enable Feral GameMode"
echo "3. Install NVIDIA/AMD drivers"
echo "4. Skip gaming optimizations"
echo ""

read -p "Enter your choice (1-4): " gaming_choice
 echo ""

case $gaming_choice in
    1)
        echo "Installing Steam and gaming packages..."
        sudo dnf install -y steam lutris wine winetricks
        echo "Gaming packages installed successfully."
        echo ""
        ;;
    2)
        echo "Enabling Feral GameMode..."
        sudo dnf install -y gamemode
        sudo systemctl enable --now gamemoded
        echo "Feral GameMode enabled successfully."
        echo ""
        ;;
    3)
        echo "Installing graphics drivers..."
        echo "Available options:"
        echo "a. NVIDIA drivers"
        echo "b. AMD drivers"
        echo "c. Skip graphics driver installation"
        
        read -p "Enter your choice (a-c): " driver_choice
        
        case $driver_choice in
            a)
                echo "Installing NVIDIA drivers..."
                sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
                echo "NVIDIA drivers installed successfully. A reboot may be required."
                ;;
            b)
                echo "Installing AMD drivers..."
                sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers libva-mesa-driver
echo "AMD drivers installed successfully."
                ;;
            c)
                echo "Skipping graphics driver installation."
                ;;
            *)
                echo "Invalid choice. Skipping graphics driver installation."
                ;;
        esac
        echo ""
        ;;
    4)
        echo "Skipping gaming optimizations."
        echo ""
        ;;
    *)
        echo "Invalid choice. Skipping gaming optimizations."
        echo ""
        ;;
esac

# 10. Clean up unnecessary packages
echo "10. Cleaning up unnecessary packages..."
sudo dnf autoremove -y
sudo dnf clean all

# 11. Show final optimization summary
echo "11. Fedora optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- DNF5 enabled as default (if available)"
echo "- Flatpak optimized"
echo "- RPM Fusion repositories enabled (optional)"
echo "- Power management configured (for laptops)"
echo "- Wayland optimized (if in Wayland session)"
echo "- Systemd-oomd configured (optional)"
echo "- Gaming optimizations applied (optional)"
echo "- Unnecessary packages cleaned up"
echo ""
echo "Reboot your system to apply all changes completely."
