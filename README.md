# essen-script
Essentials script with Makefile

# Install plugin "Remote Explore" and add config file ~/.ssh/config
```
sudo cat>>~/.ssh/config<<EOF
Host localdev
  HostName localdev
  User amnat
  StrictHostKeyChecking no
  Port 22
  IdentityFile ~/.ssh/id_ed25519
EOF
```
# Connect to localdev terminal

# Copy your git SSH Private Key to Linux Localdev
```
c:\Users\amnat\.ssh\id_ed25519 to /home/amnat/.ssh/id_ed25519

sudo cat>~/.ssh/id_ed25519<<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
your private key contents
-----END OPENSSH PRIVATE KEY-----
EOF
sudo chmod 600 ~/.ssh/id_ed25519
```

# Install essentials 
```
GIT_EMAIL="narj@live.com"
GIT_NAME="Amnat"
GIT_SETUP="git@github.com:najgit/essen-script.git"
sudo apt update \
&& sudo apt install -y curl iputils-ping net-tools curl git wget make man-db jq \
&& wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb -O ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& sudo dpkg -i ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& git config --global user.email $GIT_EMAIL \
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
&& rm ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb* \
&& cd ~/essen-script \
&& make static-ip
```
## 2. Run Make to init localdev
```
    make static-ip
```