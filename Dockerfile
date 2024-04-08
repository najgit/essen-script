FROM ubuntu:jammy

COPY . /script

WORKDIR /script 

ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt update \
&& apt-get install -y sudo \
# && echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER\
&& sudo apt install -y curl iputils-ping net-tools curl git wget make man-db jq unzip gnupg software-properties-common dnsutils ca-certificates cron openssh-client vim nano \
&& sudo add-apt-repository ppa:ondrej/php \
&& sudo apt update \
&& wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb -O ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& sudo dpkg -i ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& rm ~/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
&& sudo apt upgrade -y

RUN make setup-essentials