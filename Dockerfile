FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y git make curl software-properties-common sudo wget man openssh-server && apt-get clean
RUN apt-get install -y iptables ca-certificates lxc && apt-get clean
RUN apt-get install -y help2man && apt-get clean

RUN locale-gen en_US.*

ENV GOLANG_VERSION 1.7.5
RUN wget -qO /tmp/go${GOLANG_VERSION}.linux-amd64.tar.gz https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz     && tar -C /usr/local -xzf /tmp/go${GOLANG_VERSION}.linux-amd64.tar.gz

RUN mkdir -p /go/src/github.com/dokku/ && \
    git clone https://github.com/progrium/dokku /go/src/github.com/dokku/dokku && \
	cd /go/src/github.com/dokku/dokku && \
	git checkout v0.12.12

RUN cd /go/src/github.com/dokku/dokku && \
	make sshcommand plugn sigil version && \
	export PATH=$PATH:/usr/local/go/bin && \
	export GOPATH=/go && \
	make copyfiles PLUGIN_MAKE_TARGET=build
RUN dokku plugin:install-dependencies --core
RUN dokku plugin:install --core

RUN curl -sSL https://get.docker.com/ | sh
RUN usermod -aG docker dokku

VOLUME ["/home/dokku","/var/lib/docker","/var/lib/dokku/data","/var/lib/dokku/services"]

ENV HOME /root
WORKDIR /root
ADD ./setup.sh /root/setup.sh
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker
RUN touch /root/.firstrun

EXPOSE 22
EXPOSE 80
EXPOSE 443

CMD ["bash", "/root/setup.sh"]
