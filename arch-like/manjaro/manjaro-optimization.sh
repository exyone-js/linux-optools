#!/bin/bash

# Manjaro Specific Optimization Script

set -e

echo "Starting Manjaro specific optimization..."

# 1. Show current Manjaro version
echo "1. Manjaro version:"
 cat /etc/manjaro-release
 echo ""

# 2. Update system to latest packages
echo "2. Updating system to latest packages..."
sudo pacman -Syu --noconfirm
 echo ""

# 3. Optimize Pacman configuration
echo "3. Optimizing Pacman configuration..."

# Create a backup of the original configuration
sudo cp /etc/pacman.conf /etc/pacman.conf.backup

# Apply optimizations
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i 's/^#ILoveCandy/ILoveCandy/' /etc/pacman.conf

# Enable multilib repository
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

# Update databases
sudo pacman -Sy

echo "Pacman configuration optimized."
echo ""

# 4. Enable AUR support with pamac
echo "4. Enabling AUR support with pamac..."
if ! command -v pamac &> /dev/null; then
    echo "Installing pamac..."
    sudo pacman -S --noconfirm pamac-aur
fi

# Enable AUR in pamac
echo "Enabling AUR in pamac..."
sudo sed -i 's/^EnableAUR = false/EnableAUR = true/' /etc/pamac.conf

# Enable flatpak in pamac
echo "Enabling Flatpak in pamac..."
sudo sed -i 's/^EnableFlatpak = false/EnableFlatpak = true/' /etc/pamac.conf

echo "pamac configured with AUR and Flatpak support."
echo ""

# 5. Install Manjaro specific packages
echo "5. Installing Manjaro specific packages..."
sudo pacman -S --noconfirm --needed manjaro-settings-manager manjaro-settings-manager-kcm manjaro-hello manjaro-zsh-config manjaro-hotfixes manjaro-browser-settings manjaro-icons manjaro-firmware manjaro-tools-base manjaro-tools-pkg manjaro-tools-iso manjaro-pacman-config

 echo "Manjaro specific packages installed."
 echo ""

# 6. Enable and configure flatpak
echo "6. Enabling Flatpak and adding Flathub..."
if command -v flatpak &> /dev/null; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flatpak and Flathub enabled."
else
    echo "Installing Flatpak..."
    sudo pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flatpak and Flathub enabled."
fi
echo ""

# 7. GPU driver optimization
echo "7. GPU driver optimization..."

# Use Manjaro Settings Manager for driver installation
echo "For GPU driver optimization, please use Manjaro Settings Manager:"
echo "sudo manjaro-settings-manager"
echo ""
echo "Available GPU drivers can be installed from the Hardware Configuration section."
echo ""

# 8. Enable and configure PipeWire for audio
echo "8. Enabling PipeWire for audio..."

# Check if PipeWire is already installed
if ! command -v pipewire &> /dev/null; then
    echo "Installing PipeWire..."
    sudo pacman -S --noconfirm pipewire pipewire-pulse wireplumber pavucontrol
fi

# Enable PipeWire services
echo "Enabling PipeWire services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber
echo "PipeWire enabled."
echo ""

# 9. Install and configure gaming optimizations
echo "9. Installing gaming optimizations..."

# Install gaming packages
sudo pacman -S --noconfirm --needed game-mode lib32-game-mode mangohud lib32-mangohud wine winetricks lutris steam vkd3d-proton lib32-vkd3d-proton

# Enable GameMode
echo "Enabling GameMode..."
systemctl --user enable --now gamemoded
echo "GameMode enabled."
echo ""

# 10. Desktop environment specific optimizations
echo "10. Desktop environment specific optimizations..."

# Get current desktop environment
DESKTOP=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')

echo "Detected desktop environment: $DESKTOP"
echo ""

if [ "$DESKTOP" = "gnome" ]; then
    echo "Installing GNOME optimizations..."
    sudo pacman -S --noconfirm --needed gnome-tweaks gnome-extensions-app manjaro-gnome-extension-settings
    echo "GNOME optimizations installed."
elif [ "$DESKTOP" = "kde" ]; then
    echo "Installing KDE optimizations..."
    sudo pacman -S --noconfirm --needed kde-gtk-config kdeplasma-addons kdeconnect latte-dock manjaro-kde-settings
    echo "KDE optimizations installed."
elif [ "$DESKTOP" = "xfce" ]; then
    echo "Installing XFCE optimizations..."
    sudo pacman -S --noconfirm --needed xfce4-goodies xfce4-pulseaudio-plugin manjaro-xfce-settings
    echo "XFCE optimizations installed."
elif [ "$DESKTOP" = "cinnamon" ]; then
    echo "Installing Cinnamon optimizations..."
    sudo pacman -S --noconfirm --needed cinnamon-translations cinnamon-json-settings-daemon manjaro-cinnamon-settings
    echo "Cinnamon optimizations installed."
elif [ "$DESKTOP" = "mate" ]; then
    echo "Installing MATE optimizations..."
    sudo pacman -S --noconfirm --needed mate-tweak manjaro-mate-settings
    echo "MATE optimizations installed."
elif [ "$DESKTOP" = "budgie" ]; then
    echo "Installing Budgie optimizations..."
    sudo pacman -S --noconfirm --needed budgie-desktop-view budgie-control-center manjaro-budgie-settings
    echo "Budgie optimizations installed."
else
    echo "Unknown desktop environment. No specific optimizations applied."
fi
echo ""

# 11. Power management optimization
echo "11. Optimizing power management..."

# For laptops
if grep -q "^DMI:.*[Ll]aptop" /sys/class/dmi/id/chassis_type 2>/dev/null || grep -q "^Chassis\s*Type:\s*10" /proc/cpuinfo 2>/dev/null; then
    echo "Laptop detected. Installing power management packages..."
    sudo pacman -S --noconfirm --needed tlp tlp-rdw powertop bat acpi

    # Enable TLP
sudo systemctl enable --now tlp tlp-rdw

    # Run powertop auto-tune
    sudo powertop --auto-tune

    echo "Laptop power management configured."
else
    echo "Desktop detected. Skipping laptop power management."
fi
echo ""

# 12. Enable fstrim.timer for SSDs
echo "12. Enabling fstrim.timer for SSDs..."
sudo systemctl enable --now fstrim.timer
echo "fstrim.timer enabled."
echo ""

# 13. Apply sysctl optimizations
echo "13. Applying sysctl optimizations..."

# Create sysctl optimization file
sudo tee /etc/sysctl.d/99-manjaro-optimizations.conf <<EOF
# Manjaro system optimizations

# Memory management
vm.swappiness=10
vm.vfs_cache_pressure=50

# Network optimization
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_max_syn_backlog=4096

# Security
et.ipv4.tcp_syncookies=1
EOF

sudo sysctl --system
echo "sysctl optimizations applied."
echo ""

# 14. Clean up unnecessary packages
echo "14. Cleaning up unnecessary packages..."
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true
sudo pacman -Scc --noconfirm
echo "Cleanup completed."
echo ""

# 15. Manjaro specific recommendations
echo "15. Manjaro specific recommendations:"
echo "=================================================="
echo "- Use 'pamac-manager' for graphical package management"
echo "- Use 'manjaro-settings-manager' for system configuration"
echo "- Use 'mhwd' for hardware driver management"
echo "- Run 'sudo mhwd-kernel -li' to list installed kernels"
echo "- Run 'sudo mhwd-kernel -r linuxXXX' to remove old kernels"
echo "- Use 'manjaro-update' for system updates"
echo "- Check Manjaro Settings Manager for additional optimizations"

# 16. Show final optimization summary
echo "16. Manjaro optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- Pacman configuration optimized"
echo "- AUR support enabled with pamac"
echo "- Manjaro specific packages installed"
echo "- Flatpak enabled with Flathub"
echo "- PipeWire audio configured"
echo "- Gaming optimizations applied"
echo "- Desktop environment specific optimizations"
echo "- Power management configured (for laptops)"
echo "- fstrim.timer enabled for SSDs"
echo "- sysctl optimizations applied"
echo "- System cleaned up"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to apply all changes"
echo "- Open Manjaro Settings Manager to configure additional settings"
echo "- Use pamac-manager for graphical package management"
echo "- Run 'sudo mhwd -a pci nonfree 0300' to install recommended GPU drivers"
echo "- Use 'manjaro-hello' to explore Manjaro features"