# 移除不需要的包和依赖
sudo apt autoremove --purge -y

# 清理缓存
sudo apt clean
sudo apt autoclean

# 删除旧内核（保留当前和上一个版本）
sudo apt purge $(dpkg --list | grep 'linux-image' | awk '{print $2}' | grep -v $(uname -r) | grep -v $(uname -r | cut -d- -f1,2))
