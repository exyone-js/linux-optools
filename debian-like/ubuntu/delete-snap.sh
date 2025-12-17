# List installed snap applications
snap list

# Remove all snap applications
sudo snap remove --purge $(snap list | awk 'NR>1 {print $1}')

# Stop snap services
sudo systemctl stop snapd snapd.socket

# Disable snap services
sudo systemctl disable snapd snapd.socket

# Uninstall snapd
sudo apt purge snapd -y

# Clean snap directories
sudo rm -rf /var/cache/snapd/
sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap

# Prevent snap from being reinstalled
sudo tee /etc/apt/preferences.d/nosnap.pref <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
