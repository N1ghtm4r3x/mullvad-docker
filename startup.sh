#!/bin/bash

set -e

COUNTRY=se

default_route_ip=$(ip route | grep default | awk '{print $3}')
if [[ -z "$default_route_ip" ]]; then
    echo "No default route configured" >&2
    exit 1
fi

if [[ -z "$COUNTRY" ]]; then
    COUNTRY=se
fi

export ACCOUNT

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z "$configs" ]]; then
      bash /VPN/mullvad-wg.sh
fi

unset ACCOUNT

VPN=$(ls /etc/wireguard/ | grep mullvad-${COUNTRY} | shuf -n1 | awk '{ print substr( $0, 1, length($0)-5 ) }')
sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick

wg-quick up $VPN

docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker_network_rule="$([ ! -z "$docker_network" ] && echo "! -d $docker_network" || echo "")"
iptables -I OUTPUT ! -o $VPN -m mark ! --mark $(wg show $VPN fwmark) -m addrtype ! --dst-type LOCAL $docker_network_rule -j REJECT

# Support LOCAL_NETWORK environment variable, which was replaced by LOCAL_SUBNET
if [[ -z "$LOCAL_SUBNET" && "$LOCAL_NETWORK" ]]; then
    LOCAL_SUBNET=$LOCAL_NETWORK
fi

if [[ "$LOCAL_SUBNET" ]]; then
    echo "Allowing traffic to local subnet ${LOCAL_SUBNET}" >&2
    ip route add $LOCAL_SUBNET via $default_route_ip
    iptables -I OUTPUT -d $LOCAL_SUBNET -j ACCEPT
fi

shutdown () {
    wg-quick down $VPN
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
