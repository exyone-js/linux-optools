# 查看已安装的snap应用
snap list

# 卸载所有snap应用
sudo snap remove --purge $(snap list | awk 'NR>1 {print $1}')

# 停止snap服务
sudo systemctl stop snapd snapd.socket

# 禁用snap服务
sudo systemctl disable snapd snapd.socket

# 卸载snapd
sudo apt purge snapd -y

# 清理snap目录
sudo rm -rf /var/cache/snapd/
sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap

# 阻止snap重新安装
sudo tee /etc/apt/preferences.d/nosnap.pref <<EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
