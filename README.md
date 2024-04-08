# essen-script
Essentials script with Makefile

# Prepare Base local-dev
```
sudo apt update \
&& sudo apt install -y curl iputils-ping net-tools curl git wget make man-db jq unzip gnupg software-properties-common \
&& wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb -O ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& sudo dpkg -i ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& rm ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb
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
GIT_EMAIL="localdev@mail.com"
GIT_NAME="localdev"
GIT_SETUP="git@github.com:najgit/essen-script.git"

git config --global user.email $GIT_EMAIL \
&& git config --global user.name $GIT_NAME \
&& \
if [ -d ~/essen-script ]; then \
    echo "Already clone";
    cd ~/essen-script;
    git pull origin;
else \
    git clone $GIT_SETUP ~/essen-script; \
fi \
&& ls -la \
&& cd ~/essen-script \
&& make static-ip
```
## Manual localdev-server static ip in /etc/hosts
```
# manual add localdev IP Address
xxx.xxx.xxx.100 localdev
```