snap list
sudo snap remove --purge $(snap list | awk 'NR>1 {print $1}')
sudo systemctl stop snapd snapd.socket
sudo systemctl disable snapd snapd.socket
sudo apt purge snapd -y
sudo rm -rf /var/cache/snapd/
sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo tee /etc/apt/preferences.d/nosnap.pref <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
