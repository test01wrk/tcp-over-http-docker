#!/bin/bash
#set -e
if [ ! -z "${SSH_PUB_KEY}" ] && [ "${SSH_PUB_KEY}" != "**ssh-pub-key**" ]; then
	mkdir -p ${HOME}/.ssh
	chmod 700 ${HOME}/.ssh
	oIFS=$IFS
	IFS=";"
	for key in ${SSH_PUB_KEY}; do
		echo "SSH_PUB_KEY: $key"
		echo "$key" >> ${HOME}/.ssh/authorized_keys
	done
	IFS=$oIFS
	chmod 600 ${HOME}/.ssh/authorized_keys
	sed -i -r 's/^#?PasswordAuthentication .*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
	sed -i -r 's/^#?UsePAM .*$/UsePAM no/g' /etc/ssh/sshd_config
else
	if [ -z "${ROOT_PASS}" ] || [ "${ROOT_PASS}" == "**root-pass**" ]; then
		ROOT_PASS="$(head /dev/urandom | tr -dc 'A-Za-z0-9~!@#%^&()_+=[]{}|;:,.<>?' | head -c 16)"
	fi
	echo "ROOT_PASS: ${ROOT_PASS}"
	echo "root:${ROOT_PASS}" | chpasswd
	sed -i -r 's/^#?PermitRootLogin .*$/PermitRootLogin yes/' /etc/ssh/sshd_config
fi


if [ ! -z "${PROXY_USER_AND_PWD}" ] && [ "${PROXY_USER_AND_PWD}" != "**proxy-user-and-pwd**" ]; then
	PROXY_USER="$(echo ${PROXY_USER_AND_PWD} | cut -d' ' -f1)"
	PROXY_PWD="$(echo ${PROXY_USER_AND_PWD} | cut -d' ' -f2)"
else
	PROXY_USER="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 16)"
	PROXY_PWD="$(head /dev/urandom | tr -dc 'A-Za-z0-9~!@#%^&()_+=[]{}|;:,.<>?' | head -c 16)"
fi
echo "PROXY_USER: $PROXY_USER"
echo "PROXY_PWD: $PROXY_PWD"
htpasswd -bc /etc/squid3/passwords "$PROXY_USER" "$PROXY_PWD"
#/usr/sbin/squid3

if [ ! -z "${DNSMASQ_ADDRESS}" ] && [ "${DNSMASQ_ADDRESS}" != "**dnsmasq-address**" ]; then
	oIFS=$IFS
	IFS=";"
	for addresspair in ${DNSMASQ_ADDRESS}; do
		address="$(echo ${addresspair} | cut -d' ' -f1)"
		resolve="$(echo ${addresspair} | cut -d' ' -f2)"
		if [ ! -z "$(echo $resolve | egrep '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')" ]; then
			echo "add dnsmasq address: $address $resolve"
			sed -i -r "s|^#==Address==$|&\naddress=/$address/$resolve|" /etc/dnsmasq.conf
		fi
	done
	IFS=$oIFS
fi
echo -e "nameserver 127.0.0.1\n$(sed -r 's/^([^#]+)$/#\1/g' /etc/resolv.conf)" > /etc/resolv.conf
/etc/init.d/dnsmasq restart

#sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
# sed -i -r 's/^#?ListenAddress .*$/ListenAddress ::1/' /etc/ssh/sshd_config
# sed -i -r 's/^#?ListenAddress .*$/ListenAddress 127.0.0.1/' /etc/ssh/sshd_config
sed -i -r '/^\s*GatewayPorts /d' /etc/ssh/sshd_config
echo "GatewayPorts clientspecified" >>  /etc/ssh/sshd_config
/usr/sbin/sshd -D
