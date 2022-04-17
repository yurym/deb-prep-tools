#!/bin/bash
SERVERPORT=8388
PASSWORD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`
# --------------------------------------------------
if [ -d /root/shadowsocks ]; then
  docker compose -f /root/shadowsocks/docker-compose.yml stop
  rm -r /root/shadowsocks
fi
# --------------------------------------------------
mkdir /root/shadowsocks
# --------------------------------------------------
cat <<EOT > /root/shadowsocks/docker-compose.yml
version: "3"
services:
  shadowsocks-rust:
    image: ghcr.io/shadowsocks/ssserver-rust:latest
    restart: unless-stopped
    ports:
      - $SERVERPORT:8388
    volumes:
      - /root/shadowsocks/config.json:/etc/shadowsocks-rust/config.json
EOT
# --------------------------------------------------
cat <<EOT > /root/shadowsocks/config.json
{
    "server":"0.0.0.0",
    "mode":"tcp_and_udp",
    "server_port":8388,
    "password":"$PASSWORD",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "nameserver":"8.8.8.8"
}
EOT
# --------------------------------------------------
docker compose -f /root/shadowsocks/docker-compose.yml pull
docker compose -f /root/shadowsocks/docker-compose.yml up -d