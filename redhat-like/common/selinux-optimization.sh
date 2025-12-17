#!/bin/bash

# SELinux Configuration Optimization for Red Hat-like Systems

set -e

echo "Starting SELinux configuration optimization..."

# 1. Check current SELinux status
echo "1. Current SELinux status:"
 sestatus
 echo ""

# 2. Explain SELinux modes
echo "2. SELinux modes explanation:"
echo "=================================================="
echo "- Enforcing: SELinux security policy is enforced"
echo "- Permissive: SELinux prints warnings instead of enforcing"
echo "- Disabled: SELinux is fully disabled"
echo ""
echo "Recommended modes:"
echo "- Production servers: Enforcing"
echo "- Development servers: Permissive or Enforcing with targeted exceptions"
echo "- Testing environments: Permissive (for troubleshooting)"
echo "- Legacy systems: Consider Enforcing with careful configuration"
echo ""

# 3. Show SELinux log entries
echo "3. Recent SELinux log entries:"
 echo "(Last 20 AVC denials)"
 ausearch -m AVC -ts recent | head -20 || echo "No AVC denials found or auditd not running"
 echo ""

# 4. Configure SELinux mode
echo "4. SELinux mode configuration:"
echo "=================================================="
echo "Current SELinux mode: $(getenforce)"

read -p "Do you want to change SELinux mode? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Available SELinux modes:"
    echo "1. Enforcing"
    echo "2. Permissive"
    echo "3. Disabled (requires reboot)"
    echo ""
    read -p "Enter your choice (1-3): " selinux_choice
    
    case $selinux_choice in
        1)
            echo "Changing SELinux mode to Enforcing..."
            sudo setenforce 1
            sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
            echo "SELinux mode changed to Enforcing."
            ;;
        2)
            echo "Changing SELinux mode to Permissive..."
            sudo setenforce 0
            sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
            echo "SELinux mode changed to Permissive."
            ;;
        3)
            echo "Changing SELinux mode to Disabled..."
            echo "Warning: Disabling SELinux requires a system reboot."
            sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            echo "SELinux will be disabled after system reboot."
            ;;
        *)
            echo "Invalid choice. SELinux mode not changed."
            ;;
    esac
    echo ""
fi

# 5. SELinux policy optimization
echo "5. SELinux policy optimization:"
echo "=================================================="

# Show current SELinux policy type
policy_type=$(sestatus | grep "Policy type:" | awk '{print $3}' || echo "Unknown")
echo "Current SELinux policy type: $policy_type"
echo ""

# Show available SELinux booleans
echo "6. Common SELinux booleans that can be adjusted:"
echo "=================================================="
cat <<EOF
# Web server booleans
- httpd_can_network_connect
- httpd_can_sendmail
- httpd_enable_homedirs
- httpd_execmem

# Database booleans
- mysql_connect_any
- postgresql_connect_any
- mongod_connect_any

# SSH booleans
- ssh_chroot_rw_homedirs
- ssh_keysign

# File sharing booleans
- samba_export_all_ro
- samba_export_all_rw
- nfs_export_all_ro
- nfs_export_all_rw

# FTP booleans
- ftp_home_dir
- allow_ftpd_full_access
EOF

echo ""

# 7. Interactive boolean management
echo "7. Interactive SELinux boolean management:"
echo "=================================================="
echo "Available options:"
echo "1. List all SELinux booleans"
echo "2. Search for specific SELinux boolean"
echo "3. Toggle a specific SELinux boolean"
echo "4. Exit boolean management"
echo ""

while true; do
    read -p "Enter your choice (1-4): " boolean_choice
    echo ""
    
    case $boolean_choice in
        1)
            echo "Listing all SELinux booleans:"
            echo "(Only showing first 30 booleans)"
            getsebool -a | head -30
            echo ""
            echo "Use 'getsebool -a | grep <keyword>' to search for specific booleans."
            echo ""
            ;;
        2)
            read -p "Enter keyword to search for SELinux booleans: " keyword
            echo "SELinux booleans containing '$keyword':"
            getsebool -a | grep -i "$keyword" || echo "No booleans found matching '$keyword'"
            echo ""
            ;;
        3)
            read -p "Enter boolean name to toggle: " boolean_name
            current_value=$(getsebool "$boolean_name" 2>/dev/null || echo "Unknown")
            if [ "$current_value" = "Unknown" ]; then
                echo "Boolean '$boolean_name' not found."
            else
                echo "Current value of $boolean_name: $current_value"
                
                if [[ $current_value == *on* ]]; then
                    echo "Disabling $boolean_name..."
                    sudo setsebool -P "$boolean_name" off
                else
                    echo "Enabling $boolean_name..."
                    sudo setsebool -P "$boolean_name" on
                fi
                echo "New value of $boolean_name: $(getsebool "$boolean_name")"
            fi
            echo ""
            ;;
        4)
            echo "Exiting SELinux boolean management..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1-4."
            echo ""
            ;;
    esac
done

# 8. SELinux troubleshooting tools
echo "8. SELinux troubleshooting tools:"
echo "=================================================="
echo "Useful SELinux commands:"
echo "- sestatus: Show SELinux status"
echo "- getenforce: Show current SELinux mode"
echo "- setenforce: Change SELinux mode temporarily"
echo "- semanage: Manage SELinux configuration"
echo "- restorecon: Restore file contexts"
echo "- audit2allow: Generate SELinux allow rules from logs"
echo "- ausearch: Search audit logs"
echo "- sealert: Analyze SELinux denials"
echo ""

# 9. SELinux file context management
echo "9. SELinux file context management:"
read -p "Do you want to restore file contexts for a specific directory? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter directory path to restore contexts: " dir_path
    echo "Restoring SELinux contexts for $dir_path..."
    sudo restorecon -Rv "$dir_path"
    echo "File contexts restored."
    echo ""
fi

echo "SELinux configuration optimization completed!"
echo "Key recommendations:"
echo "  - For production systems, keep SELinux in Enforcing mode"
echo "  - For development, use Permissive mode to identify issues"
echo "  - Regularly check SELinux logs for denials"
echo "  - Use targeted booleans instead of disabling SELinux entirely"
echo "  - Backup SELinux configuration before making major changes"
echo "  - Remember that disabling SELinux requires a system reboot"
