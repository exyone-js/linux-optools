#!/bin/bash

# Snap to Deb Conversion Helper for Ubuntu

set -e

echo "Starting Snap to Deb conversion helper..."

# 1. Check if snap is installed
if ! command -v snap &> /dev/null; then
    echo "Error: snap is not installed. This script is for systems with snap installed."
    exit 1
fi

# 2. List installed snap applications
echo "1. Installed snap applications:"
snap list

# 3. Create mapping of common snap apps to deb packages
cat <<EOF > /tmp/snap_to_deb_mapping.txt
# Common snap apps and their deb alternatives
# Format: snap_name,deb_package_name,notes
code,code,Use official Microsoft repository for VS Code deb
firefox,firefox,Use official Mozilla repository for Firefox deb
spotify,spotify-client,Use official Spotify repository
slack,slack-desktop,Use official Slack repository
zoom,zoom,Use official Zoom repository
discord,discord,Use official Discord repository
telegram-desktop,telegram-desktop,Available in Ubuntu repositories
brave,brave-browser,Use official Brave repository
element-desktop,element-desktop,Use official Element repository
vlc,vlc,Available in Ubuntu repositories
gimp,gimp,Available in Ubuntu repositories
inkscape,inkscape,Available in Ubuntu repositories
thunderbird,thunderbird,Available in Ubuntu repositories
chromium,chromium-browser,Available in Ubuntu repositories
alacritty,alacritty,Available in Ubuntu repositories (Ubuntu 22.04+)
EOF

# 4. Check for deb alternatives
echo -e "\n2. Checking for deb alternatives:"
echo "===================================="

# Get list of installed snaps
snap_apps=$(snap list | awk 'NR>1 {print $1}')

# Create result file
result_file="/tmp/snap_to_deb_results.txt"
> "$result_file"

has_deb_alternatives=false

for app in $snap_apps; do
    # Skip system snaps
    if [[ "$app" =~ ^(core|core18|core20|core22|core24|snapd|bare)$ ]]; then
        continue
    fi
    
    # Check mapping for deb alternative
    deb_alt=$(grep -i "^$app," /tmp/snap_to_deb_mapping.txt | cut -d, -f2 || true)
    notes=$(grep -i "^$app," /tmp/snap_to_deb_mapping.txt | cut -d, -f3- || true)
    
    if [ -n "$deb_alt" ]; then
        has_deb_alternatives=true
        echo -e "✓ $app"
        echo -e "  Deb alternative: $deb_alt"
        if [ -n "$notes" ]; then
            echo -e "  Notes: $notes"
        fi
        echo -e "  Command to remove snap: sudo snap remove --purge $app"
        echo -e "  Command to install deb: sudo apt install -y $deb_alt"
        echo -e ""
        
        # Write to result file
        echo "$app,$deb_alt,$notes" >> "$result_file"
    else
        echo -e "✗ $app"
        echo -e "  No known deb alternative found"
        echo -e ""
    fi
done

# 5. Show summary
echo "===================================="
echo "3. Summary:"
if $has_deb_alternatives; then
    echo "Found deb alternatives for some snap apps. See above for details."
    echo "Result file saved to: $result_file"
    echo -e ""
    echo "4. Recommended next steps:"
    echo "   1. Review the deb alternatives above"
    echo "   2. Remove snap apps you want to replace"
    echo "   3. Install the deb alternatives"
    echo "   4. Consider using snap list --all to remove old revisions"
    echo "   5. Use apt-fast or apt for faster package management"
else
    echo "No deb alternatives found for your installed snap apps."
fi

# 6. Provide auto-conversion option
echo -e "\n5. Auto-conversion option:"
read -p "Do you want to automatically convert all snap apps to deb alternatives? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting auto-conversion..."
    
    while IFS=, read -r snap_app deb_app notes; do
        if [ -n "$snap_app" ] && [ -n "$deb_app" ]; then
            echo -e "\nConverting $snap_app to $deb_app..."
            
            # Remove snap app
            echo "Removing snap $snap_app..."
            sudo snap remove --purge "$snap_app" 2>/dev/null || true
            
            # Install deb app
            echo "Installing deb $deb_app..."
            sudo apt install -y "$deb_app" 2>/dev/null || {
                echo "Failed to install $deb_app. Check notes: $notes"
                continue
            }
            
            echo "✓ Successfully converted $snap_app to $deb_app"
        fi
    done < "$result_file"
    
    echo -e "\nAuto-conversion completed!"
fi

# 7. Cleanup
echo -e "\n6. Cleaning up temporary files..."
rm -f /tmp/snap_to_deb_mapping.txt /tmp/snap_to_deb_results.txt

echo -e "\nSnap to Deb conversion helper completed!"
echo "Note: Some apps may require adding external repositories for their deb versions."
echo "Check the notes above for specific instructions."