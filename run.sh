#!/bin/bash
#set -e
if [ -z "$CHISEL_KEY" ] || [ "$CHISEL_KEY" == "**chisel-key**" ]; then
	CHISEL_KEY="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)"
fi
echo "chisel key: $CHISEL_KEY"
sed -i "s/RG_CHISEL_KEY/$CHISEL_KEY/g" /etc/supervisor/conf.d/chisel.conf
service supervisor start

if [ ! -z "$SSH_PUB_KEY" ] && [ "$SSH_PUB_KEY" != "**ssh-pub-key**" ]; then
	mkdir -p ${HOME}/.ssh
	chmod 700 ${HOME}/.ssh
	echo "$SSH_PUB_KEY" > ${HOME}/.ssh/authorized_keys
	chmod 600 ${HOME}/.ssh/authorized_keys
else
	if [ -z "$ROOT_PASS" ] || [ "$ROOT_PASS" == "**root-pass**" ]; then
		ROOT_PASS="$(head /dev/urandom | tr -dc 'A-Za-z0-9~!@#%^&()_+=[]{}|;:,.<>?' | head -c 16)"
	fi
	echo "initial password: $ROOT_PASS"
	echo "root:$ROOT_PASS" | chpasswd
	sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
fi
#sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^#ListenAddress ::$/ListenAddress ::1/' /etc/ssh/sshd_config
sed -i 's/^#ListenAddress 0.0.0.0$/ListenAddress 127.0.0.1/' /etc/ssh/sshd_config
/usr/sbin/sshd -D
