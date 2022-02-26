FROM debian:stable-slim

RUN mkdir /VPN

COPY mullvad-wg.sh /VPN
COPY startup.sh /VPN

RUN chmod +x /VPN/startup.sh; chmod +x /VPN/mullvad-wg.sh; apt update; apt install -y iptables iproute2 jq curl openresolv wireguard iputils-ping; sed -i '/sysctl/d' /usr/bin/wg-quick

ENTRYPOINT /VPN/startup.sh

CMD tail -f /dev/null
