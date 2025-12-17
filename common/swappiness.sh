# Check current value
cat /proc/sys/vm/swappiness

# Temporary modification (recommended: 10-30, 10 for servers)
sudo sysctl vm.swappiness=10

# Permanent modification
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Adjust cache pressure
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
