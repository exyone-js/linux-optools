# 查看当前值
cat /proc/sys/vm/swappiness

# 临时修改（推荐值：10-30，服务器建议10）
sudo sysctl vm.swappiness=10

# 永久修改
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# 调整缓存压力
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
