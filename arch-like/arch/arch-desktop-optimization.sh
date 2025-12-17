#!/bin/bash

# Arch Linux Desktop Optimization Script

set -e

echo "Starting Arch Linux desktop optimization..."

# 1. Show current desktop environment
echo "1. Current desktop environment:"
 echo $XDG_CURRENT_DESKTOP
 echo ""

# 2. Update system
echo "2. Updating system..."
sudo pacman -Syu --noconfirm
 echo ""

# 3. Install essential desktop packages
echo "3. Installing essential desktop packages..."
sudo pacman -S --noconfirm --needed nvidia intel amd mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader dxvk lib32-dxvk mangohud lib32-mangohud obs-studio ffmpeg vlc gimp inkscape libreoffice-fresh chromium firefox element-desktop discord steam flatpak

 echo "Essential desktop packages installed."
 echo ""

# 4. Enable Flatpak and add Flathub
echo "4. Enabling Flatpak and adding Flathub..."
if command -v flatpak &> /dev/null; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "Flatpak and Flathub enabled."
else
    echo "Flatpak is not installed. Please install it manually if needed."
fi
echo ""

# 5. GPU driver optimization
echo "5. GPU driver optimization..."

# Detect GPU
echo "Detecting GPU..."
GPU=$(lspci -k | grep -A 2 -E "(VGA|3D)" | grep "Kernel driver in use" | cut -d: -f2 | xargs || echo "Unknown")
echo "GPU driver in use: $GPU"
echo ""

# Install appropriate drivers based on GPU
if echo "$GPU" | grep -i nvidia; then
    echo "NVIDIA GPU detected. Installing NVIDIA-specific packages..."
    sudo pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils nvidia-settings nvidia-prime
    echo "NVIDIA packages installed."
elif echo "$GPU" | grep -i amd; then
    echo "AMD GPU detected. Installing AMD-specific packages..."
    sudo pacman -S --noconfirm --needed xf86-video-amdgpu lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau
    echo "AMD packages installed."
elif echo "$GPU" | grep -i intel; then
    echo "Intel GPU detected. Installing Intel-specific packages..."
    sudo pacman -S --noconfirm --needed xf86-video-intel lib32-mesa-vdpau libva-intel-driver lib32-libva-intel-driver mesa-vdpau
    echo "Intel packages installed."
else
    echo "Unknown GPU. Installing generic GPU packages..."
    sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader
    echo "Generic GPU packages installed."
fi
echo ""

# 6. Enable and configure PipeWire for audio
echo "6. Enabling PipeWire for audio..."

# Install PipeWire
sudo pacman -S --noconfirm --needed pipewire pipewire-pulse wireplumber pavucontrol pipewire-alsa pipewire-jack lib32-pipewire-jack

# Enable PipeWire services
echo "Enabling PipeWire services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber
echo "PipeWire enabled."
echo ""

# 7. Install and configure gaming optimizations
echo "7. Installing gaming optimizations..."

# Install gaming packages
sudo pacman -S --noconfirm --needed game-mode lib32-game-mode mangohud lib32-mangohud wine winetricks lutris steam vkd3d-proton lib32-vkd3d-proton

# Enable GameMode
echo "Enabling GameMode..."
systemctl --user enable --now gamemoded
echo "GameMode enabled."

# Configure MangoHud for Steam
echo "Configuring MangoHud for Steam..."
mkdir -p ~/.config/MangoHud

cat > ~/.config/MangoHud/MangoHud.conf <<EOF
# MangoHud configuration
position=top-left
enabled=0
EOF

echo "MangoHud configured."
echo ""

# 8. Desktop environment specific optimizations
echo "8. Desktop environment specific optimizations..."

if echo "$XDG_CURRENT_DESKTOP" | grep -i gnome; then
    echo "GNOME detected. Installing GNOME optimizations..."
    sudo pacman -S --noconfirm --needed gnome-tweaks gnome-extensions-app

    # Enable useful GNOME extensions
    echo "Enabling GNOME extensions..."
    # Note: This requires gnome-extensions-app to be installed and the user to be logged in
    echo "Please manually enable extensions using gnome-extensions-app."
    echo "Recommended extensions:"
    echo "- Dash to Dock"
    echo "- User Themes"
    echo "- AppIndicator and KStatusNotifierItem Support"
    echo "- GSConnect"
    echo "- Blur My Shell"
elif echo "$XDG_CURRENT_DESKTOP" | grep -i kde; then
    echo "KDE detected. Installing KDE optimizations..."
    sudo pacman -S --noconfirm --needed kde-gtk-config kdeplasma-addons kdeconnect latte-dock

    # Enable compositor vsync
    echo "Enabling compositor vsync..."
    kwriteconfig5 --file ~/.config/kwinrc --group Compositing --key Enabled true
    kwriteconfig5 --file ~/.config/kwinrc --group Compositing --key OpenGLIsUnsafe false
    kwriteconfig5 --file ~/.config/kwinrc --group Compositing --key VSync glx
    echo "KDE compositor configured."
elif echo "$XDG_CURRENT_DESKTOP" | grep -i xfce; then
    echo "XFCE detected. Installing XFCE optimizations..."
    sudo pacman -S --noconfirm --needed xfce4-goodies xfce4-pulseaudio-plugin

    # Enable compositor vsync
    echo "Enabling compositor vsync..."
    xfconf-query -c xfwm4 -p /general/vblank_mode -s glx
    echo "XFCE compositor configured."
else
    echo "Unknown desktop environment. No specific optimizations applied."
fi
echo ""

# 9. Install and configure power management
echo "9. Installing power management..."

# For laptops
echo "Checking if this is a laptop..."
if grep -q "^DMI:.*[Ll]aptop" /sys/class/dmi/id/chassis_type 2>/dev/null || grep -q "^Chassis\s*Type:\s*10" /proc/cpuinfo 2>/dev/null; then
    echo "Laptop detected. Installing power management packages..."
    sudo pacman -S --noconfirm --needed tlp tlp-rdw powertop

    # Enable TLP
echo "Enabling TLP..."
sudo systemctl enable --now tlp tlp-rdw

    # Run powertop auto-tune
echo "Running powertop auto-tune..."
sudo powertop --auto-tune

    # Install laptop-specific packages
    echo "Installing laptop-specific packages..."
    sudo pacman -S --noconfirm --needed bat acpi

    echo "Laptop power management configured."
else
    echo "Desktop detected. Skipping laptop power management."
fi
echo ""

# 10. Install and configure system monitoring
echo "10. Installing system monitoring tools..."
sudo pacman -S --noconfirm --needed htop iotop bashtop btop nmon virt-manager conky

# Configure Conky (optional)
echo "Configuring Conky..."
mkdir -p ~/.config/conky

cat > ~/.config/conky/conky.conf <<EOF
# Conky configuration
background yes
update_interval 1.0
total_run_times 0

own_window yes
own_window_type normal
own_window_transparent yes
own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager

double_buffer yes

use_xft yes
xftfont DejaVu Sans Mono:size=10
xftalpha 0.8

draw_shades no
draw_outline no
draw_borders no
draw_graph_borders no

default_color white
default_shade_color black
default_outline_color white

alignment top_right
gap_x 10
gap_y 10

no_buffers yes
cpu_avg_samples 2
net_avg_samples 2

override_utf8_locale yes

minimum_size 250 5
maximum_width 500

TEXT
SYSTEM ${hr 2}
Hostname: $nodename
Uptime: $uptime
Kernel: $kernel

CPU ${hr 2}
${cpugraph cpu0 32,150 0000ff 00ff00}
CPU 1: ${cpu cpu1}% ${cpubar cpu1}
CPU 2: ${cpu cpu2}% ${cpubar cpu2}
CPU 3: ${cpu cpu3}% ${cpubar cpu3}
CPU 4: ${cpu cpu4}% ${cpubar cpu4}

MEMORY ${hr 2}
RAM: $mem/$memmax ($memperc%)
${membar 8,150}
Swap: $swap/$swapmax ($swapperc%)
${swapbar 8,150}

DISK ${hr 2}
Root: ${fs_used /}/${fs_size /} (${fs_free_perc /}% free)
${fs_bar 8,150 /}
Home: ${fs_used /home}/${fs_size /home} (${fs_free_perc /home}% free)
${fs_bar 8,150 /home}

NETWORK ${hr 2}
${addr wlan0}
${downspeedgraph wlan0 32,150 0000ff 00ff00}${alignr}${upspeedgraph wlan0 32,150 0000ff 00ff00}
Down: ${downspeed wlan0} ${alignr}Up: ${upspeed wlan0}
Down total: ${totaldown wlan0} ${alignr}Up total: ${totalup wlan0}
EOF

echo "Conky configured."
echo ""

# 11. Install and configure development tools
echo "11. Installing development tools..."
sudo pacman -S --noconfirm --needed git vim code docker docker-compose podman buildah

# Enable Docker
echo "Enabling Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo "Docker enabled. Please logout and login to apply group changes."
echo ""

# 12. Final cleanup and recommendations
echo "12. Final cleanup..."
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true
sudo pacman -Scc --noconfirm

echo "Cleanup completed."

# 13. Show final optimization summary
echo "13. Arch Linux desktop optimization completed!"
echo "=================================================="
echo "Key optimizations applied:"
echo "- System updated to latest packages"
echo "- Essential desktop packages installed"
echo "- Flatpak and Flathub enabled"
echo "- GPU drivers optimized"
echo "- PipeWire audio configured"
echo "- Gaming optimizations applied"
echo "- Desktop environment specific optimizations"
echo "- Power management configured (for laptops)"
echo "- System monitoring tools installed"
echo "- Development tools installed"
echo "- System cleaned up"
echo ""
echo "Recommended next steps:"
echo "- Reboot your system to apply all changes"
echo "- Logout and login to apply Docker group changes"
echo "- Install additional desktop extensions/themes as needed"
echo "- Configure MangoHud for your preferred games"
echo "- Run 'sudo powertop --auto-tune' periodically for power optimization"
echo "- Use 'pacman -Syu' regularly to keep your system updated"