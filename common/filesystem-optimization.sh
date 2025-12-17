# Filesystem Optimization

# Optimize Disk Scheduler (for SSD and NVMe)
# Check current scheduler: cat /sys/block/sda/queue/scheduler
# Recommended for SSD/NVMe: mq-deadline or none/kyber
echo "Optimizing disk scheduler..."
sudo tee -a /etc/udev/rules.d/60-ssd-scheduler.rules <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
EOF

# Enable TRIM (for SSDs)
echo "Enabling TRIM support..."
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Optimize Filesystem Mount Options
echo "Optimizing /etc/fstab mount options..."
# Note: Please modify the following configuration based on actual situation, this is just an example
# Recommended mount options: noatime, nodiratime, discard (or ssd), errors=remount-ro

# Optimize Inode Limits
echo "Optimizing inode and filesystem parameters..."
sudo tee -a /etc/sysctl.conf <<EOF

# Filesystem Optimization Configuration
# Increase file descriptor limit
fs.file-max = 2097152

# Increase inode cache
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 128

# Optimize EXT4 filesystem
# vm.dirty_background_ratio = 5
# vm.dirty_ratio = 10
EOF

# Apply Configuration
sudo sysctl -p

echo "Filesystem optimization completed!"
echo "Please manually check and modify /etc/fstab to add appropriate mount options:"
echo "  - For SSD: noatime, nodiratime, discard (or ssd)"
echo "  - For HDD: noatime, nodiratime, deadline"
echo "  - General: errors=remount-ro"
echo "Example: UUID=xxx / ext4 noatime,nodiratime,discard,errors=remount-ro 0 1"