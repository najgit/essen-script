# essen-script
Essentials script with Makefile

# Prepare Base local-dev
```
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER;\
sudo apt install -y curl iputils-ping net-tools git wget make man-db jq zip unzip gnupg software-properties-common dnsutils ca-certificates cron openssh-client vim nano locales \
&& sudo add-apt-repository ppa:ondrej/php \
&& sudo apt update \
&& sudo apt upgrade -y \
&& TZ=Asia/Bangkok \
&& sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ | sudo tee /etc/timezone \
&& echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment \
&& echo "en_US.UTF-8 UTF-8"  | sudo tee -a /etc/locale.gen \
&& echo "LANG=en_US.UTF-8"  | sudo tee /etc/locale.conf \
&& sudo locale-gen en_US.UTF-8 \
&& sudo groupadd localdev -g 1002 \
&& sudo useradd localdev -u 1002 -g 1002 -m -s /bin/bash \
&& sudo usermod -aG sudo localdev \
&& echo "localdev ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/localdev \
&& sudo apt-get install open-vm-tools open-vm-tools-desktop \
&& sudo apt-get install build-essential module-assistant \
  linux-headers-virtual linux-image-virtual \
&& sudo dpkg-reconfigure open-vm-tools

#create mount dir /d/t2pdev, /d/dblkdev, /d/m2pdev

#edit /etc/fstab
.host:/t2pdev /d/t2pdev fuse.vmhgfs-fuse defaults,allow_other,uid=1002,gid=1002   0 0
.host:/m2pdev /d/m2pdev fuse.vmhgfs-fuse defaults,allow_other,uid=1002,gid=1002   0 0
.host:/dblkdev /d/dblkdev fuse.vmhgfs-fuse defaults,allow_other,uid=1002,gid=1002   0 0
.host:/stbdev /d/stbdev fuse.vmhgfs-fuse defaults,allow_other,uid=1002,gid=1002   0 0
```

# Install plugin "Remote Explore" and add config file ~/.ssh/config
```
# map localdev in /etc/hosts
# start localdev VM and get IP address login with user=localdev, password=111156
  ifconfig | grep 'inet'

# manual add localdev IP Address
xxx.xxx.xxx.xxx localdev

# add Widnows/Mac User Host .ssh config
sudo cat>>~/.ssh/config<<EOF
Host localdev
  HostName localdev
  User localdev
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  Port 22
  IdentityFile ~/.ssh/id_ed25519
EOF
```
# Connect to localdev terminal

# Copy your git SSH Private Key to Linux Localdev
```
cp ~/.ssh/id_ed25519 to /home/localdev/.ssh/id_ed25519

OR manual

cat>~/.ssh/id_ed25519<<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
your private key contents
-----END OPENSSH PRIVATE KEY-----
EOF

chmod 600 ~/.ssh/id_ed25519
```

# Install essentials set GIT_EMAIL, GIT_NAME, GIT_SETUP
```
cd ~/essen-script \
&& make setup-localdev
```
## Manual localdev new static ip in /etc/hosts
```
# manual add localdev IP Address
xxx.xxx.xxx.100 localdev
```

##  Connect to localdev terminal again
```
cd ~/essen-script \
&& make setup-essentials
```
