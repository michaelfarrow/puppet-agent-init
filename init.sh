#!/bin/bash

hostname=""

while [[ "$hostname" == "" ]]
	do
	printf 'Agent Hostname: '
	read -r hostname
done

default_environment="production"
environment=""

while [[ "$environment" == "" ]]
	do
	printf "Environment [$default_environment]: "
	read -r environment

	if [[ "$default_environment" != "" ]] && [[ "$environment" == "" ]]
		then
		environment="$default_environment"
	fi
done

default_domain="$1"
domain=""

while [[ "$domain" == "" ]]
	do
	printf "Domain [$default_domain]: "
	read -r domain

	if [[ "$default_domain" != "" ]] && [[ "$domain" == "" ]]
		then
		domain="$default_domain"
	fi
done

server_prefix="foreman"

if [[ "$2" != "" ]]
	then
	server_prefix="$2"
fi

default_server="$server_prefix.$domain"
server=""

while [[ "$server" == "" ]]
	do
	printf "Server [$default_server]: "
	read -r server

	if [[ "$default_server" != "" ]] && [[ "$server" == "" ]]
		then
		server="$default_server"
	fi
done

default_ca_server="$server_prefix.$domain"
ca_server=""

while [[ "$ca_server" == "" ]]
	do
	printf "CA Server [$default_ca_server]: "
	read -r ca_server

	if [[ "$default_ca_server" != "" ]] && [[ "$ca_server" == "" ]]
		then
		ca_server="$default_ca_server"
	fi
done

echo "$hostname" > /etc/hostname
hostname $hostname
cat > /etc/hosts << EOF
127.0.0.1   $hostname.$domain $hostname localhost localhost.localdomain
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

apt-get update
apt-get install -y puppet

cat > /etc/puppet/puppet.conf << EOF

[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = \$vardir/ssl
pluginsync  = true
report      = true
splay       = true
ca_server       = $ca_server
certname        = $hostname.$domain
environment     = $environment
server          = $server

EOF

/usr/bin/service puppet stop
/usr/bin/service puppet start

/usr/bin/puppet resource service puppet ensure=running enable=true

/usr/bin/puppet agent --enable
/usr/bin/puppet agent --test
