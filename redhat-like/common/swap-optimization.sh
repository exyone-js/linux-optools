#!/bin/bash

# Swap Space Optimization for Red Hat-like Systems

set -e

echo "Starting swap space optimization..."

# 1. Show current swap usage
echo "1. Current swap usage:"
 free -h
 echo ""

# 2. Show swap devices
echo "2. Swap devices:"
 swapon --show
 echo ""

# 3. Show current swappiness value
echo "3. Current swappiness value:"
 cat /proc/sys/vm/swappiness
 echo ""

# 4. Explain swappiness
echo "4. Swappiness explanation:"
echo "=================================================="
echo "Swappiness value (0-100) controls how aggressively the kernel swaps memory:"
echo "- 0: Only swap when absolutely necessary"
echo "- 10-20: Recommended for desktop systems"
echo "- 10: Recommended for servers with plenty of RAM"
echo "- 60: Default value"
echo "- 100: Aggressive swapping"
echo ""
echo "Recommended values:"
echo "- Desktop systems: 10-20"
echo "- Server systems: 5-10"
echo "- Systems with limited RAM: 60 (default)"
echo ""

# 5. Optimize swappiness
echo "5. Optimizing swappiness:"
echo "=================================================="

read -p "Do you want to change swappiness value? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter new swappiness value (0-100): " swappiness_value
    
    # Set temporary swappiness
    sudo sysctl -w vm.swappiness=$swappiness_value
    
    # Set permanent swappiness
    echo "vm.swappiness=$swappiness_value" | sudo tee -a /etc/sysctl.conf
    
    echo "Swappiness changed to $swappiness_value."
    echo ""
fi

# 6. Optimize cache pressure
echo "6. Optimizing vm.vfs_cache_pressure:"
echo "=================================================="
echo "Current cache pressure value: $(cat /proc/sys/vm/vfs_cache_pressure)"
echo ""
echo "Cache pressure explanation:"
echo "- Controls how aggressively the kernel reclaims cache memory"
echo "- Default: 100"
echo "- Recommended: 50-75 for better performance"
echo "- Lower value: Keep cache longer"
echo "- Higher value: Reclaim cache more aggressively"
echo ""

read -p "Do you want to change cache pressure value? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter new cache pressure value (0-200): " cache_pressure_value
    
    # Set temporary cache pressure
    sudo sysctl -w vm.vfs_cache_pressure=$cache_pressure_value
    
    # Set permanent cache pressure
    echo "vm.vfs_cache_pressure=$cache_pressure_value" | sudo tee -a /etc/sysctl.conf
    
    echo "Cache pressure changed to $cache_pressure_value."
    echo ""
fi

# 7. Swap file/partition management
echo "7. Swap management options:"
echo "=================================================="
echo "Available swap management options:"
echo "1. Create a swap file"
echo "2. Remove a swap file"
echo "3. Add a swap partition"
echo "4. Remove a swap partition"
echo "5. Exit swap management"
echo ""

while true; do
    read -p "Enter your choice (1-5): " swap_choice
    echo ""
    
    case $swap_choice in
        1)
            echo "Creating a swap file..."
            read -p "Enter swap file size (e.g., 4G): " swap_size
            read -p "Enter swap file path (default: /swapfile): " swap_path
            swap_path=${swap_path:-/swapfile}
            
            # Create swap file
            sudo fallocate -l "$swap_size" "$swap_path"
            sudo chmod 600 "$swap_path"
            sudo mkswap "$swap_path"
            sudo swapon "$swap_path"
            
            # Add to fstab
            echo "$swap_path none swap defaults 0 0" | sudo tee -a /etc/fstab
            
            echo "Swap file created successfully at $swap_path with size $swap_size."
            echo ""
            ;;
        2)
            echo "Removing a swap file..."
            echo "Current swap files:"
            swapon --show | grep file
            
            read -p "Enter swap file path to remove: " swap_path
            
            # Remove from swapon
            sudo swapoff "$swap_path"
            
            # Remove from fstab
            sudo sed -i "/$swap_path/d" /etc/fstab
            
            # Delete swap file
            sudo rm -f "$swap_path"
            
            echo "Swap file $swap_path removed successfully."
            echo ""
            ;;
        3)
            echo "Adding a swap partition..."
            echo "Available disk partitions:"
            lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
            
            read -p "Enter swap partition path (e.g., /dev/sdb1): " swap_partition
            
            # Check if partition exists
            if [ ! -b "$swap_partition" ]; then
                echo "Error: Partition $swap_partition does not exist."
                continue
            fi
            
            # Create swap filesystem
            sudo mkswap "$swap_partition"
            
            # Add to swapon
            sudo swapon "$swap_partition"
            
            # Add to fstab
            UUID=$(blkid -s UUID -o value "$swap_partition")
            echo "UUID=$UUID none swap defaults 0 0" | sudo tee -a /etc/fstab
            
            echo "Swap partition $swap_partition added successfully."
            echo ""
            ;;
        4)
            echo "Removing a swap partition..."
            echo "Current swap partitions:"
            swapon --show | grep partition
            
            read -p "Enter swap partition path to remove (e.g., /dev/sdb1): " swap_partition
            
            # Remove from swapon
            sudo swapoff "$swap_partition"
            
            # Remove from fstab
            UUID=$(blkid -s UUID -o value "$swap_partition" 2>/dev/null || true)
            if [ -n "$UUID" ]; then
                sudo sed -i "/UUID=$UUID/d" /etc/fstab
            else
                sudo sed -i "/$swap_partition/d" /etc/fstab
            fi
            
            echo "Swap partition $swap_partition removed successfully."
            echo "Note: The partition itself was not deleted, only removed from swap configuration."
            echo ""
            ;;
        5)
            echo "Exiting swap management..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1-5."
            echo ""
            ;;
    esac
done

# 8. Show final swap configuration
echo "8. Final swap configuration:"
 free -h
 echo ""

 swapon --show
 echo ""

# 9. Apply sysctl changes
echo "9. Applying sysctl changes..."
sudo sysctl -p

# 10. Recommendations
echo "10. Swap space recommendations:"
echo "=================================================="
echo "- For systems with < 2GB RAM: Swap size = 2x RAM"
echo "- For systems with 2-8GB RAM: Swap size = 1x RAM"
echo "- For systems with 8-64GB RAM: Swap size = 0.5x RAM"
echo "- For systems with > 64GB RAM: Swap size = 4-16GB (based on usage)"
echo "- For hibernation: Swap size = RAM + 1GB"
echo ""
echo "Swap space optimization completed!"
echo "Key optimizations applied:"
echo "  - Swappiness value adjusted for optimal performance"
echo "  - Cache pressure optimized for better memory management"
echo "  - Swap devices managed according to your choices"
echo "  - All changes made permanent"
