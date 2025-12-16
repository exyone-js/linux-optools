sudo apt autoremove --purge -y
sudo apt clean
sudo apt autoclean
# remove old kernels (keep the current and previous versions)
sudo apt purge $(dpkg --list | grep 'linux-image' | awk '{print $2}' | grep -v $(uname -r) | grep -v $(uname -r | cut -d- -f1,2))
