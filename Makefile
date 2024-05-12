ROOT := ${CURDIR}

OS_ARCH :=$(shell uname -m)#x86_64, aarch64, (darwin)arm64
OS_KERNEL :=$(shell uname -s | tr '[:upper:]' '[:lower:]')#linux(x86_64, aarch64), darwin
OS_ARCH_GO :=$(shell if [ "${OS_ARCH}" = "x86_64" ]; then echo "amd64"; else echo "arm64"; fi)

NVM_VERSION := v0.39.7
GO_VERSION := 1.20.14
GO_PRIVATE :=gitlab.t2p.co.th

define STATIC_CONFIG
network:
  ethernets:
    ADAPTER:
      dhcp4: false
      addresses:
        - IP_ADDRESS/IP_PREFIXLEND
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: default
          via: IP_GATEWAY
  version: 2
endef

define ZSH_CONFIG
zstyle ':completion::complete:make:*:targets' call-command true

NEWLINE=$$'\n'
autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '(%b) '

setopt PROMPT_SUBST
PROMPT='%F{green}%n%f@%F{green}%m [%F{red}`date +%d\(%a\)/%b/%y` %*%f%F{green}]%f %F{blue}%~%f %F{red}$${vcs_info_msg_0_}%f$${NEWLINE}$$ '
endef

# export STATIC_CONFIG
RED=\033[0;31m
NC=\033[0m

.PHONY: list #hide#
list:
	@grep -E "^\.PHONY:" Makefile \
	| grep -v ":default" \
	| sed "s/.PHONY:/  make /"  \
	| sed "s/ #opt://" \
	| sed "s/ #hint:/   \t||/" \
	| grep -v '#hide#' \
	| grep -v -E "^[[:space:]]*_" | sort

.PHONY: setup-essentials
setup-essentials: setup-docker setup-awscli setup-terraform setup-ansible setup-go setup-nvm default-node16 setup-serverless-util setup-nginx setup-php56 setup-php7 setup-php8 setup-php83
	@sudo cp ${ROOT}/bin/Switchphp /usr/local/bin/ \
	&& sudo chmod +x /usr/local/bin/Switchphp \
	&& sudo systemctl disable apache2 \
	&& sudo usermod -aG docker localdev \
	&& sudo apt install -y xclip \
	&& echo "DONE!"

.PHONY: static-ip
static-ip: export STATIC_CONFIG:=${STATIC_CONFIG}
static-ip:
	@ifconfig | grep -v 'RX ' | grep -v 'TX ' | grep -v 'inet6 '| grep -v 'ether '  \
	&& default="$(shell ifconfig | head -n 1 | cut -d':' -f1)" \
	&& ip="" \
	&& while [ "$${ip}" = "" ]; do  \
		read  -p "Select adapter to set static-ip [$$(printf '${RED}')$${default}$$(printf '${NC}')]: " adapter \
		&& if [ "$${adapter}" = "" ]; then adapter=$${default}; fi \
		&& gateway=$$(ip -j route show 0.0.0.0/0 dev $${adapter} | jq -r '.[0].gateway') \
		&& ip=$$(ip -j -o -f inet addr show $${adapter} | jq -r '.[0].addr_info[0].local') \
		&& if [ "$${ip}" = "" ]; then echo "\ninvalid adapter input!!\n"; fi; \
	done \
	&& prefixlen=$$(ip -j -o -f inet addr show $${adapter} | jq -r '.[0].addr_info[0].prefixlen') \
	&& read  -p "Set new static-ip [$$(printf '${RED}')$${ip}$$(printf '${NC}')]: " newip \
	&& if [ "$${newip}" = "" ]; then newip=$${ip}; fi \
	&& VERSION=$(cat /etc/os-release | grep VERSION_ID|cut -d'=' -f2|cut -d'"' -f2) \
	&& yaml_file="00-installer-config.yaml" \
	&& if [ "$$VERSION" = "24.04" ]; then sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.`date +%d-%m-%y.%M%S`; yaml_file="50-cloud-init.yaml"; fi \
	&& if [ !"$$VERSION" = "24.04" ]; then sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.`date +%d-%m-%y.%M%S`; fi \
	&& echo "$${STATIC_CONFIG}" | sed "s#ADAPTER#$${adapter}#"  | sed "s#IP_ADDRESS#$${newip}#" | sed "s#IP_PREFIXLEND#$${prefixlen}#" | sed "s#IP_GATEWAY#$${gateway}#" | sudo tee /etc/netplan/$${yaml_file} \
	&& sudo netplan apply \
	&& echo "=========== =================== =========== ========================" \
	&& echo "=========== set static COMPLETE! restart to apply effect ===========" \
	&& echo "=========== =================== =========== ========================" 

.PHONY: setup-docker
setup-docker:
	@cd ${ROOT} \
	&& curl -fsSL https://get.docker.com -o get-docker.sh \
	&& sudo sh get-docker.sh \
	&& rm get-docker.sh

.PHONY: setup-awscli
setup-awscli:
	@cd ${ROOT} \
	&& sudo apt remove awscli \
	&& curl "https://awscli.amazonaws.com/awscli-exe-linux-$$(uname -m).zip" -o "awscliv2.zip" \
	&& unzip -o awscliv2.zip \
	&& sudo ./aws/install --update \
	&& rm -rf ${ROOT}/aws \
	&& rm ${ROOT}/awscliv2.zip

.PHONY: setup-terraform
setup-terraform:
	@cd ${ROOT} \
	&& wget -O- https://apt.releases.hashicorp.com/gpg | \
		gpg --dearmor | \
		sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
	&& gpg --no-default-keyring \
		--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
		--fingerprint \
	&& echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
		https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | \
		sudo tee /etc/apt/sources.list.d/hashicorp.list \
	&& sudo apt update \
	&& sudo apt install -y terraform

.PHONY: setup-ansible
setup-ansible:
	@cd ${ROOT}\
	&& sudo apt-add-repository ppa:ansible/ansible \
	&& sudo apt update \
	&& sudo apt install -y ansible

.PHONY: setup-nvm
setup-nvm:
	@cd ${ROOT} \
	&& curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash

.PHONY: default-node16
default-node16:
	@export NVM_DIR="$$HOME/.nvm" \
	&& [ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" \
	&& [ -s "$$NVM_DIR/bash_completion" ] && \. "$$NVM_DIR/bash_completion" \
	&& nvm install v16

.PHONY: setup-go
setup-go:
	@cd ${ROOT} \
	&& if [ "$${IN_DOCKER}" = "" ]; then read  -p "Select Golang Version to Install [$$(printf '${RED}')${GO_VERSION}$$(printf '${NC}')]: " newversion ; fi \
	&& GO_VERSION=${GO_VERSION} \
	&& if [ ! "$${newversion}" = "" ]; then GO_VERSION=$${newversion}; fi \
	&& sudo mkdir -p /d/datago /datago \
	&& sudo chown localdev:localdev /d/datago /datago \
	&& echo "go$${GO_VERSION}.${OS_KERNEL}-${OS_ARCH_GO}" \
	&& curl -L -o golang.tar.gz https://go.dev/dl/go$${GO_VERSION}.${OS_KERNEL}-${OS_ARCH_GO}.tar.gz \
	&& sudo rm -rf /usr/local/go \
	&& sudo tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz \
	&& FINDFOUND=$$(grep -ro 'export GOPATH=/d/datago' ~/.bashrc | sort -t: -u -k1,1) \
	&& if [ ! "$$FINDFOUND" = "export GOPATH=/d/datago" ]; \
		then \
			{ \
			echo ""; \
			echo "#golang env"; \
			echo "export GOPRIVATE=${GO_PRIVATE}"; \
			echo "export GOROOT=/usr/local/go"; \
			echo "export GOPATH=/d/datago"; \
			echo 'export PATH=$$GOPATH/bin:$$GOROOT/bin:$$PATH'; \
			echo ""; \
			}  >> ~/.bashrc; \
		fi \
	&& FINDFOUND=$$(grep -ro 'export GOPATH=/d/datago' ~/.zshrc | sort -t: -u -k1,1) \
	&& if [ ! "$$FINDFOUND" = "export GOPATH=/d/datago" ]; \
		then \
			{ \
			echo ""; \
			echo "#golang env"; \
			echo "export GOPRIVATE=${GO_PRIVATE}"; \
			echo "export GOROOT=/usr/local/go"; \
			echo "export GOPATH=/d/datago"; \
			echo 'export PATH=$$GOPATH/bin:$$GOROOT/bin:$$PATH'; \
			echo ""; \
			}  >> ~/.zshrc; \
		fi		 \
	&& export GOPRIVATE=${GO_PRIVATE} \
	&& export GOROOT=/usr/local/go \
	&& export GOPATH=/d/datago \
	&& export PATH=$$GOPATH/bin:$$GOROOT/bin:$$PATH \
	&& go version

.PHONY: setup-serverless-util
setup-serverless-util:
	@export NVM_DIR="$$HOME/.nvm" \
	&& [ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" \
	&& [ -s "$$NVM_DIR/bash_completion" ] && \. "$$NVM_DIR/bash_completion" \
	&& export GOROOT=/usr/local/go \
	&& export GOPATH=/d/datago \
	&& export PATH=$$GOPATH/bin:$$GOROOT/bin:$$PATH \
	&& npm i -g @redocly/cli@latest \
	&& npm install -g pnpm \
    && npm i -g serverless \
    && /usr/local/go/bin/go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@latest \
    && /usr/local/go/bin/go install github.com/jfeliu007/goplantuml/cmd/goplantuml@latest \
    && sudo apt install -y libsecret-1-dev pass gnupg2  plantuml

.PHONY: setup-nginx
setup-nginx:
	@sudo apt-get install -y \
	nginx nginx-extras

.PHONY: setup-php56
setup-php56:
	@sudo apt update \
	&& sudo apt install -y php5.6-mysql \
	php5.6-xml \
	php5.6-xdebug \
	php5.6-curl \
	php5.6-bcmath \
	php5.6-apcu \
	php5.6-bz2 \
	php5.6-gd \
	php5.6-gnupg \
	php5.6-imagick \
	php5.6-intl \
	php5.6-memcached \
	php5.6-redis \
	php5.6-soap \
	php5.6-tidy \
	php5.6-xmlrpc \
	php5.6-zip \
	php5.6-gmp \
	php5.6-mcrypt \
	php5.6-mbstring

.PHONY: setup-php7
setup-php7:
	@sudo apt update \
	&& sudo apt install -y php7.4-mysql \
	php7.4-xml \
	php7.4-xdebug \
	php7.4-curl \
	php7.4-bcmath \
	php7.4-apcu \
	php7.4-bz2 \
	php7.4-gd \
	php7.4-gnupg \
	php7.4-imagick \
	php7.4-intl \
	php7.4-memcached \
	php7.4-redis \
	php7.4-soap \
	php7.4-tidy \
	php7.4-xmlrpc \
	php7.4-zip \
	php7.4-gmp \
	php7.4-mbstring

.PHONY: setup-php8
setup-php8:
	@sudo apt update \
	&& sudo apt install -y \
	php8.0 \
	php8.0-common \
	php8.0-mysql \
	php8.0-mysqli \
	php8.0-xml \
	php8.0-xdebug \
	php8.0-curl \
	php8.0-bcmath \
	php8.0-apcu \
	php8.0-bz2 \
	php8.0-gd \
	php8.0-gnupg \
	php8.0-imagick \
	php8.0-intl \
	php8.0-mbstring \
	php8.0-memcached \
	php8.0-redis \
	php8.0-soap \
	php8.0-tidy \
	php8.0-xmlrpc \
	php8.0-zip \
	php8.0-gmp

.PHONY: setup-php83
setup-php83:
	@sudo apt update \
	&& sudo apt install -y \
	php8.3 \
	php8.3-common \
	php8.3-mysql \
	php8.3-mysqli \
	php8.3-xml \
	php8.3-xdebug \
	php8.3-curl \
	php8.3-bcmath \
	php8.3-apcu \
	php8.3-bz2 \
	php8.3-gd \
	php8.3-gnupg \
	php8.3-imagick \
	php8.3-intl \
	php8.3-mbstring \
	php8.3-memcached \
	php8.3-redis \
	php8.3-soap \
	php8.3-tidy \
	php8.3-xmlrpc \
	php8.3-zip \
	php8.3-gmp

.PHONY: setup-zsh
setup-zsh: export ZSH_CONFIG:=${ZSH_CONFIG}
setup-zsh:
	@sudo apt update && sudo apt install -y curl git \
	&& FINDFOUND="$(shell bash -c "if [ -f ~/.zshrc ]; then grep -ro ':completion::complete:make:\*:targets' ~/.zshrc | sort -t: -u -k1,1; else echo ''; fi")" \
	&& if [ "$${FINDFOUND}" = "" ]; then \
		echo "Install zsh" \
		&& rm -rf ~/.oh-my-zsh \
		&& sudo apt install -y zsh \
		&& sh -c "$$(echo "n" | curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
		&& echo "$${ZSH_CONFIG}" | sudo tee -a ~/.zshrc \
		&& sed -i "s/plugins=(git)/plugins=(gitfast)/g" ~/.zshrc; \
	fi \
	&& git config --global oh-my-zsh.hide-status 1 \
	&& git config --global oh-my-zsh.hide-dirty 1 \
	&& git config --global pager.branch false

.PHONY: setup-localdev
setup-localdev:
	@GIT_EMAIL="your@mail.com" \
	GIT_NAME="your" \
	GIT_SETUP="git@github.com:najgit/essen-script.git" \
	&& read  -p "Setup git email [$$(printf '${RED}')$${GIT_EMAIL}$$(printf '${NC}')]: " new_email \
	&& read  -p "Setup git user name [$$(printf '${RED}')$${GIT_NAME}$$(printf '${NC}')]: " new_name \
	&& read  -p "Setup git remote-dev repo [$$(printf '${RED}')$${GIT_SETUP}$$(printf '${NC}')]: " new_repo \
	&& if [ ! "$${new_email}" = "" ]; then GIT_EMAIL=$${new_email}; fi \
	&& if [ ! "$${new_name}" = "" ]; then GIT_NAME=$${new_name}; fi \
	&& if [ ! "$${new_repo}" = "" ]; then GIT_SETUP=$${new_repo}; fi \
	&& git config --global user.email $${GIT_EMAIL} \
	&& git config --global user.name $${GIT_NAME} \
	&& \
	if [ -d ~/essen-script ]; then \
		echo "Already clone"; \
		cd ~/essen-script; \
		git pull origin; \
	else \
		git clone $${GIT_SETUP} ~/essen-script; \
	fi \
	&& ls -la \
	&& cd ~/essen-script \
	&& make setup-zsh \
	&& FINDFOUND="$(shell bash -c "if [ -f ~/.zshrc ]; then grep -ro 'pbcopy' ~/.zshrc ; fi")" \
	&& if [ "$${FINDFOUND}" = "" ]; then echo "alias pbcopy='xclip -sel clip'" | sudo tee -a ~/.zshrc ; fi \
	&& FINDFOUND="$(shell bash -c "if [ -f ~/.bashrc ]; then grep -ro 'pbcopy' ~/.bashrc; fi")" \
	&& if [ "$${FINDFOUND}" = "" ]; then echo "alias pbcopy='xclip -sel clip'" | sudo tee -a ~/.bashrc ; fi \
	&& echo "set go private" \
	&& FINDFOUND="$(shell bash -c "if [ -f ~/.zshrc ]; then grep -ro 'GOPRIVATE=' ~/.zshrc ; fi")" \
	&& if [ "$${FINDFOUND}" = "" ]; then echo "GOPRIVATE=gitlab.t2p.co.th" | sudo tee -a ~/.zshrc ; fi \
	&& FINDFOUND="$(shell bash -c "if [ -f ~/.bashrc ]; then grep -ro 'GOPRIVATE=' ~/.bashrc; fi")" \
	&& if [ "$${FINDFOUND}" = "" ]; then echo "GOPRIVATE=gitlab.t2p.co.th" | sudo tee -a ~/.bashrc ; fi \
	&& echo "make go get use SSH insteam of HTTP" \
	&& git config --global url."git@gitlab.t2p.co.th:".insteadOf "http://gitlab.t2p.co.th/" \
	&& make static-ip 
