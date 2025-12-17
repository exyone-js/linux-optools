# Edit sysctl configuration
sudo tee -a /etc/sysctl.conf <<EOF
# Reduce swap frequency
vm.swappiness=10
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# Increase memory overcommit ratio
vm.overcommit_ratio=95

# Optimize page reclaim
vm.min_free_kbytes=65536

# Transparent Huge Pages
# Recommended to disable for database servers
# echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF

# Apply configuration
sudo sysctl -p
