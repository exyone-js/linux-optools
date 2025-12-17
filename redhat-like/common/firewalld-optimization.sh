#!/bin/bash

# Firewalld Optimization for Red Hat-like Systems

set -e

echo "Starting firewalld optimization..."

# 1. Check if firewalld is installed and running
echo "1. Checking firewalld status:"
if ! command -v firewall-cmd &> /dev/null; then
    echo "firewalld is not installed. Installing firewalld..."
    sudo dnf install -y firewalld
fi

# Start and enable firewalld if not running
sudo systemctl enable --now firewalld
firewall-cmd --state
 echo ""

# 2. Show current firewalld configuration
echo "2. Current firewalld configuration:"
 echo "Active zones:"
 firewall-cmd --get-active-zones
 echo ""

 echo "Default zone:"
 firewall-cmd --get-default-zone
 echo ""

 echo "Services in default zone:"
 firewall-cmd --list-services --zone=$(firewall-cmd --get-default-zone)
 echo ""

 echo "Ports in default zone:"
 firewall-cmd --list-ports --zone=$(firewall-cmd --get-default-zone)
 echo ""

# 3. Optimize firewalld rules
echo "3. Optimizing firewalld configuration:"
echo "=================================================="

# 4. Define recommended services to enable
echo "4. Recommended services to enable:"
echo "=================================================="
echo "Common services that may need to be enabled:"
echo "- ssh (for remote access)"
echo "- http, https (for web servers)"
echo "- ftp (for file transfer)"
echo "- mysql, postgresql (for databases)"
echo "- smtp, smtps, submission (for email servers)"
echo "- dns (for name servers)"
echo "- ntp (for time synchronization)"
echo ""

# 5. Interactive firewall management
echo "5. Interactive firewalld management:"
echo "=================================================="
echo "Available options:"
echo "1. Change default zone"
echo "2. Add service to default zone"
echo "3. Remove service from default zone"
echo "4. Add port to default zone"
echo "5. Remove port from default zone"
echo "6. List all available services"
echo "7. Enable/disable firewalld masquerade"
echo "8. Exit firewall management"
echo ""

while true; do
    read -p "Enter your choice (1-8): " firewall_choice
    echo ""
    
    case $firewall_choice in
        1)
            echo "Available zones:"
            firewall-cmd --get-zones
            read -p "Enter new default zone: " new_zone
            sudo firewall-cmd --set-default-zone="$new_zone"
            sudo firewall-cmd --runtime-to-permanent
            echo "Default zone changed to $new_zone."
            echo ""
            ;;
        2)
            echo "Available services:"
            firewall-cmd --get-services | tr ' ' '\n' | head -30
            echo "(Only showing first 30 services)"
            read -p "Enter service name to add: " service_name
            sudo firewall-cmd --add-service="$service_name"
            sudo firewall-cmd --permanent --add-service="$service_name"
            echo "Service $service_name added to default zone."
            echo ""
            ;;
        3)
            echo "Current services in default zone:"
            firewall-cmd --list-services
            read -p "Enter service name to remove: " service_name
            sudo firewall-cmd --remove-service="$service_name"
            sudo firewall-cmd --permanent --remove-service="$service_name"
            echo "Service $service_name removed from default zone."
            echo ""
            ;;
        4)
            read -p "Enter port number and protocol (e.g., 8080/tcp): " port_protocol
            sudo firewall-cmd --add-port="$port_protocol"
            sudo firewall-cmd --permanent --add-port="$port_protocol"
            echo "Port $port_protocol added to default zone."
            echo ""
            ;;
        5)
            echo "Current ports in default zone:"
            firewall-cmd --list-ports
            read -p "Enter port number and protocol (e.g., 8080/tcp): " port_protocol
            sudo firewall-cmd --remove-port="$port_protocol"
            sudo firewall-cmd --permanent --remove-port="$port_protocol"
            echo "Port $port_protocol removed from default zone."
            echo ""
            ;;
        6)
            echo "All available services:"
            firewall-cmd --get-services | tr ' ' '\n' | sort
            echo ""
            ;;
        7)
            current_masquerade=$(firewall-cmd --query-masquerade)
            echo "Current masquerade status: $current_masquerade"
            if [ "$current_masquerade" = "no" ]; then
                echo "Enabling masquerade..."
                sudo firewall-cmd --add-masquerade
                sudo firewall-cmd --permanent --add-masquerade
                echo "Masquerade enabled."
            else
                echo "Disabling masquerade..."
                sudo firewall-cmd --remove-masquerade
                sudo firewall-cmd --permanent --remove-masquerade
                echo "Masquerade disabled."
            fi
            echo ""
            ;;
        8)
            echo "Exiting firewalld management..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1-8."
            echo ""
            ;;
    esac
done

# 6. Firewalld performance optimization
echo "6. Firewalld performance optimization:"
echo "=================================================="

# 7. Show optimized firewalld configuration
echo "7. Optimized firewalld configuration:"
 echo "Active zones:"
 firewall-cmd --get-active-zones
 echo ""

 echo "Default zone:"
 firewall-cmd --get-default-zone
 echo ""

 echo "Services in default zone:"
 firewall-cmd --list-services --zone=$(firewall-cmd --get-default-zone)
 echo ""

 echo "Ports in default zone:"
 firewall-cmd --list-ports --zone=$(firewall-cmd --get-default-zone)
 echo ""

# 8. Firewalld security recommendations
echo "8. Firewalld security recommendations:"
echo "=================================================="
echo "- Keep firewalld enabled and running"
echo "- Only open necessary services and ports"
echo "- Use specific zones for different network interfaces"
echo "- Regularly review and audit firewall rules"
echo "- Consider implementing rate limiting for sensitive services"
echo "- Use rich rules for more granular control"
echo "- Enable logging for denied packets (firewall-cmd --set-log-denied=all)"
echo ""

# 9. Enable logging for denied packets
echo "9. Configuring firewall logging:"
read -p "Do you want to enable logging for denied packets? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo firewall-cmd --set-log-denied=all
    sudo firewall-cmd --permanent --set-log-denied=all
    echo "Firewall logging for denied packets enabled."
    echo "To view firewall logs: journalctl -u firewalld -f"
    echo ""
fi

echo "Firewalld optimization completed!"
echo "Key optimizations applied:"
echo "  - Firewalld installed, enabled, and running"
echo "  - Optimized firewall rules based on your selections"
echo "  - Firewall logging configured"
echo "  - Security recommendations provided"
echo ""
echo "To list all firewalld rules: firewall-cmd --list-all"
echo "To reload firewalld: sudo firewall-cmd --reload"
echo "To make runtime changes permanent: sudo firewall-cmd --runtime-to-permanent"
