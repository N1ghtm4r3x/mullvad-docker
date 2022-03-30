FROM alpine:3.15

RUN mkdir /VPN
COPY mullvad-wg.sh /VPN
COPY startup.sh /VPN

RUN chmod +x /VPN/startup.sh \
    && chmod +x /VPN/mullvad-wg.sh \
    && apk update \
    && apk add ip6tables \
               findutils \
               iptables \
               iproute2 \
               jq \
               curl \
               openresolv \
               wireguard-tools \
               iputils \
               bash \
               grep \
               net-tools \
               ts \
    && sed -i '/sysctl/d' /usr/bin/wg-quick

ENTRYPOINT bash /VPN/startup.sh
