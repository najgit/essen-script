# essen-script
Essentials script with Makefile

# Step
## 1. Copy SSH Private Key From Windows to Linux Localdev
```
c:\Users\amnat\.ssh\id_ed25519 to /home/amnat/.ssh/id_ed25519

#install essentials 
sudo apt update \
&& sudo apt install -y curl iputils-ping net-tools curl git wget \
&& wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& sudo dpkg -i ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& \
if [ -d ~/essen-script ]; then \
    echo "Already clone";
    cd ~/essen-script;
    git pull origin;
else \
    git clone git@github.com:najgit/essen-script.git ~/essen-script; \
fi \
&& ls -la \
&& rm ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb* \
&& cd ~/essen-script
```
## 2. Run Make to init localdev
```
    make static-ip
```