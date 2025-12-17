# Journald Log Optimization Script

echo "Starting journald log optimization..."

# 1. Backup original configuration
echo "1. Backing up original configuration..."
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak

# 2. Optimize journald configuration
echo "2. Optimizing journald configuration..."
sudo tee -a /etc/systemd/journald.conf <<EOF

# Journald optimization settings
[Journal]
# Limit journal size (recommended: 50-200MB)
SystemMaxUse=100M
RuntimeMaxUse=50M
SystemMaxFileSize=20M
RuntimeMaxFileSize=10M

# Compress journal files
Compress=yes

# Disable persistent storage (use volatile storage for better performance)
# Storage=volatile

# Set journal retention policy
MaxRetentionSec=2week

# Forward logs to syslog (if needed)
# ForwardToSyslog=no

# Reduce log verbosity
LogLevel=notice

# Rate limiting to prevent log flooding
RateLimitIntervalSec=30s
RateLimitBurst=1000
EOF

# 3. Restart journald service
echo "3. Restarting journald service..."
sudo systemctl restart systemd-journald

# 4. Clean up old journal files
echo "4. Cleaning up old journal files..."
# Keep only the last 2 weeks of logs
sudo journalctl --vacuum-time=2weeks
# Keep only 100MB of logs
sudo journalctl --vacuum-size=100M

# 5. Check journald status
echo "5. Checking journald status..."
sudo systemctl status systemd-journald --no-pager

# 6. View journald usage statistics
echo "6. Journald usage statistics..."
sudo journalctl --disk-usage

# 7. Configure log rotation for syslog (if using syslog)
echo "7. Configuring syslog log rotation..."
# Note: Most systems use journald by default now, but if you're using syslog, consider optimizing logrotate

# 8. Enable persistent journal if needed
echo "8. Persistent journal configuration..."
echo "Current journal storage type: $(grep -E '^Storage=' /etc/systemd/journald.conf | cut -d= -f2)"
echo "To enable persistent journal: sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald"
echo "To disable persistent journal: sudo sed -i 's/^Storage=.*/Storage=volatile/' /etc/systemd/journald.conf && sudo systemctl restart systemd-journald"

echo "\nJournald log optimization completed!"
echo "Key changes made:"
echo "  - Limited journal size to 100MB system-wide and 50MB runtime"
echo "  - Enabled journal compression"
echo "  - Set log retention to 2 weeks"
echo "  - Enabled rate limiting to prevent log flooding"
echo "  - Reduced log verbosity to notice level"
echo "  - Cleaned up old journal files"

echo "\nTo view logs: journalctl"
echo "To view recent errors: journalctl -p err -b"
echo "To follow logs: journalctl -f"