# Process Priority Optimization Script

echo "Starting process priority optimization..."

# 1. Optimize Process Scheduler
echo "1. Optimizing process scheduler..."
# Check current scheduler: cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Recommendation: schedutil or ondemand for desktops, performance for servers

# Set CPU scheduler to performance mode (for servers)
# echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 2. Optimize OOM Killer Configuration
echo "2. Optimizing OOM killer configuration..."
# Backup original configuration
sudo cp /etc/sysctl.conf /etc/sysctl.conf.oom.bak

# Configure OOM killer
sudo tee -a /etc/sysctl.conf <<EOF

# OOM killer optimization configuration
# Set OOM score adjustment to protect critical processes
# vm.oom_score_adj = -1000  # Editing /proc/[pid]/oom_score_adj directly is safer

# Adjust OOM killer memory pressure trigger point
vm.overcommit_memory = 1
vm.overcommit_ratio = 95

# 3. Optimize process scheduling parameters
# Increase maximum number of processes
kernel.pid_max = 4194304

# Optimize real-time process scheduling
kernel.sched_rt_period_us = 1000000
kernel.sched_rt_runtime_us = 950000

# Optimize CFS scheduler
kernel.sched_min_granularity_ns = 1000000
kernel.sched_wakeup_granularity_ns = 1500000
kernel.sched_latency_ns = 4000000
kernel.sched_child_runs_first = 0
EOF

# Apply configuration
sudo sysctl -p

# 3. Set nice values for critical services
echo "3. Setting priorities for critical services..."
# Note: Modify service names and priorities according to actual situation
# Example: Set nice value for sshd to -10
echo "# Set priorities for critical services" | sudo tee -a /etc/security/limits.conf

# 4. Optimize system service startup priorities
echo "4. Optimizing system service startup priorities..."
# For systemd systems, use systemctl set-property to adjust service resource limits

# Example: Limit CPU and memory usage for a specific service
# sudo systemctl set-property some-service.service CPUWeight=100 MemoryMax=512M

# 5. Check current system process status
echo "5. Current system process status..."
echo "Viewing high-priority processes:"
ps aux --sort=-priority | head -10

echo "\nViewing top 10 processes by memory usage:"
ps aux --sort=-%mem | head -10

echo "\nViewing top 10 processes by CPU usage:"
ps aux --sort=-%cpu | head -10

echo "\nProcess priority optimization completed!"
echo "Recommendations:"
echo "  - For desktop systems, consider using schedutil or ondemand scheduler"
echo "  - For server systems, consider using performance scheduler"
echo "  - Adjust OOM scores and resource limits for critical services based on actual needs"
echo "  - Use systemctl set-property to adjust service resource limits"
echo "Example: sudo systemctl set-property sshd.service Nice=-10"