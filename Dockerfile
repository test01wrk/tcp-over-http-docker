FROM ubuntu:14.04
MAINTAINER test01wrk <test01wrk@163.com>

RUN mv /etc/apt/sources.list /etc/apt/sources.list_bak \
    && grep -o '^deb.*' /etc/apt/sources.list_bak | \
        sed -r 's|https?://archive.ubuntu.com/ubuntu/|http://cn.archive.ubuntu.com/ubuntu/|g' > /etc/apt/sources.list \
    && cat /etc/apt/sources.list \
    && apt-get update && apt-get install -y vim openssh-server supervisor \
    && mkdir -p /var/run/sshd \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY run.sh /run.sh
COPY etc /etc
COPY data /data

EXPOSE 80

ENTRYPOINT ["/run.sh"]
CMD [""]