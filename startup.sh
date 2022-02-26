#!/bin/bash

set -e

export ACCOUNT

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z "$configs" ]]; then
      bash /VPN/mullvad-wg.sh
fi

#bash /VPN/mullvad-wg.sh

unset ACCOUNT

VPN=$(ls /etc/wireguard/ | grep mullvad-${COUNTRY} | shuf -n1 | awk '{ print substr( $0, 1, length($0)-5 ) }')
sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick
wg-quick up $VPN

docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker_network_rule="$([ ! -z "$docker_network" ] && echo "! -d $docker_network" || echo "")"
iptables -I OUTPUT ! -o $VPN -m mark ! --mark $(wg show $VPN fwmark) -m addrtype ! --dst-type LOCAL $docker_network_rule -j REJECT

shutdown () {
    wg-quick down $VPN
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
