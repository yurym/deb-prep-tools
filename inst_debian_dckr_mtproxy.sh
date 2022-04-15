#!/bin/bash
CLIENTS=1
SERVERPORT=443
# --------------------------------------------------
if [ -d /root/mtproxy ]; then
  docker compose -f /root/mtproxy/docker-compose.yml stop
  rm -r /root/mtproxy
fi
# --------------------------------------------------
mkdir /root/mtproxy
# --------------------------------------------------
if ((CLIENTS >= 1)); then
  SECRET=`head -c 16 /dev/urandom | xxd -ps`
  echo -n "SECRET=$SECRET" > /root/mtproxy/.env
  echo "tg://proxy?server=`curl -4s icanhazip.com`&port=$SERVERPORT&secret=$SECRET" > /root/mtproxy/links.txt
fi
if ((CLIENTS > 1)); then
  for ((i=2;i<=CLIENTS;i++)); do
    SECRET=`head -c 16 /dev/urandom | xxd -ps`
    echo -n ",$SECRET" >> /root/mtproxy/.env
    echo "tg://proxy?server=`curl -4s icanhazip.com`&port=$SERVERPORT&secret=$SECRET" >> /root/mtproxy/links.txt
  done
fi
# --------------------------------------------------
SECRET='${SECRET}'
cat <<EOT > /root/mtproxy/docker-compose.yml
version: "3"
services:
  mtproxy:
    image: telegrammessenger/proxy:latest
    restart: unless-stopped
    ports:
      - $SERVERPORT:443
    volumes:
      - /root/mtproxy/config:/data
    environment:
      - SECRET=${SECRET}
EOT
# --------------------------------------------------
docker compose -f /root/mtproxy/docker-compose.yml pull
docker compose -f /root/mtproxy/docker-compose.yml up -d