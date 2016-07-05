#!/bin/bash
#set -e
if [ -z "${CHISEL_KEY}" ] || [ "${CHISEL_KEY}" == "**chisel-key**" ]; then
	CHISEL_KEY="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)"
fi
echo "CHISEL_KEY: ${CHISEL_KEY}"
sed -i "s/RG_CHISEL_KEY/${CHISEL_KEY}/g" /etc/supervisor/conf.d/chisel.conf
if [ -z "${PROXY_URL}" ] || [ "${PROXY_URL}" == "**proxy-url**" ]; then
	PROXY_URL="https://github.com"
fi
echo "PROXY_URL: ${PROXY_URL}"
sed -i "s|RG_PROXY_URL|${PROXY_URL}|g" /etc/supervisor/conf.d/chisel.conf
service supervisor start

/usr/sbin/cron
echo '#!/bin/bash' > /run_cron.sh && chmod a+x /run_cron.sh
echo 'echo "cron job run at $(date)"' >> /run_cron.sh
echo "HEARTBEAT_URL: ${HEARTBEAT_URL}"
if [ ! -z "${HEARTBEAT_URL}" ] || [ "${HEARTBEAT_URL}" == "**heartbeat-url**" ]; then
	echo "wget -q -U 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0' \
			-O - ${HEARTBEAT_URL} && echo && echo 'heartbeat ok'" >> /run_cron.sh
fi
if [ -z "${CRON_RUN_TIME}" ] || [ "${CRON_RUN_TIME}" == "**cron-run-time**" ]; then
	CRON_RUN_TIME='0 * * * *'
fi
echo "CRON_RUN_TIME: ${CRON_RUN_TIME}"
echo "${CRON_RUN_TIME} /run_cron.sh | tee -a /proc/1/fd/1" | crontab

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
#sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
sed -i -r 's/^#?ListenAddress .*$/ListenAddress ::1/' /etc/ssh/sshd_config
sed -i -r 's/^#?ListenAddress .*$/ListenAddress 127.0.0.1/' /etc/ssh/sshd_config
/usr/sbin/sshd -D
