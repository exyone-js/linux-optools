# TCP/IP Network Optimization
# Increase TCP Connection Limits
sudo tee -a /etc/sysctl.conf <<EOF

# Network Optimization Configuration
# Increase Local Port Range
net.ipv4.ip_local_port_range = 1024 65535

# Increase TCP Connection Limits
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096

# Optimize TCP Buffers
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Enable TCP Fast Open
net.ipv4.tcp_fastopen = 3

# Optimize TCP Recycling and Timeouts
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30

# Enable SYN Cookies Protection
net.ipv4.tcp_syncookies = 1

# Increase SYN Queue Length
net.ipv4.tcp_max_syn_backlog = 4096

# Optimize TCP Keepalive Parameters
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 60

# Disable IPv6 (if not needed)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
EOF

# Apply Configuration
sudo sysctl -p