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
PROMPT='%F{green}%n%f@%F{green}%m [%F{red}%*%f%F{green}]%f %F{blue}%~%f %F{red}$${vcs_info_msg_0_}%f$${NEWLINE}$$ '
endef

# export STATIC_CONFIG
RED=\033[0;31m
NC=\033[0m


.PHONY: help
help:
	@echo "Hello"

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
	&& sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.backup.`date +%d-%m-%y.%M%S` \
	&& echo "$${STATIC_CONFIG}" | sed "s#ADAPTER#$${adapter}#"  | sed "s#IP_ADDRESS#$${newip}#" | sed "s#IP_PREFIXLEND#$${prefixlen}#" | sed "s#IP_GATEWAY#$${gateway}#" | sudo tee /etc/netplan/00-installer-config.yaml \
	&& sudo netplan apply \
	&& echo "=========== =================== =========== ========================" \
	&& echo "=========== set static COMPLETE! restart to apply effect ===========" \
	&& echo "=========== =================== =========== ========================" 

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
