FROM ubuntu:14.04
MAINTAINER test01wrk <test01wrk@163.com>

RUN mv /etc/apt/sources.list /etc/apt/sources.list_bak \
	&& grep -o '^deb.*' /etc/apt/sources.list_bak | \
		sed -r 's|https?://[^/]*/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' > /etc/apt/sources.list

RUN apt-get update && apt-get install -y vim openssh-server supervisor squid apache2-utils dnsmasq dnsutils \
	&& mkdir -p /var/run/sshd \
	&& sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

COPY run.sh /run.sh
COPY etc /etc

EXPOSE 22
EXPOSE 3128

ENTRYPOINT ["/run.sh"]
CMD [""]