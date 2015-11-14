#!/bin/bash
if [ "${PUBKEY}" = "" ] || [ "${USERNAME}" = "" ] || [ "${VHOSTNAME}" = "" ]; then
    echo "You need to specify a ssh PUBKEY, a USERNAME and VHOSTNAME"
    exit 1
fi

# Regenerate SSH keys
if [ -f "/root/.firstrun" ]; then
    rm /etc/ssh/ssh_host_*
    dpkg-reconfigure openssh-server
fi

# Install Docker and Buildstep Image
/usr/local/bin/wrapdocker
sleep 2
chmod 777 /var/run/docker.sock

docker pull $(grep PREBUILT_STACK_URL /root/dokku/Makefile | head -n1 | cut -d' ' -f3)

# Install remaining dokku stuff
if [ -f "/root/.firstrun" ]; then
    cd /root/dokku
    make sshcommand
    echo $PUBKEY | sshcommand acl-add dokku ${USERNAME}
    echo $VHOSTNAME > /home/dokku/VHOST

    dokku plugin:install https://github.com/dokku/dokku-postgres.git
    dokku plugin:install https://github.com/dokku/dokku-elasticsearch.git
    dokku plugin:install https://github.com/dokku/dokku-mysql.git
    dokku plugin:install https://github.com/dokku/dokku-redis.git
    dokku plugin:install https://github.com/dokku/dokku-rabbitmq.git
fi

# Start SSH and Nginx
service ssh start
service nginx start

if [ -f "/root/.firstrun" ]; then
    unlink /root/.firstrun
fi

dokku ps:restartall

sleep 99999d
