# deb-prep-tools

Just download the script and run it from root. Tested on Debian 11.

## Docker

```
apt-get -y install curl; curl -s https://raw.githubusercontent.com/yurym/deb-prep-tools/main/inst_debian_docker.sh | bash
docker compose version
```

## Speedtest

```
apt-get -y install curl; curl -s https://raw.githubusercontent.com/yurym/deb-prep-tools/main/inst_debian_spdtst.sh | bash
speedtest -o test.byfly.by
speedtest -s 1119

```

## WireGuard

```
apt-get -y install curl; curl -s https://raw.githubusercontent.com/yurym/deb-prep-tools/main/inst_debian_wg.sh | bash
```

Default vars: `CLIENTS=3`, `ETHIF=eth0`, ``SERVERIP=`curl -4s icanhazip.com` `` and `SERVERPORT=51194`.

At least two alternate server ports are required: `SERVERPORTALT=53,51820`. Port forwarding starts from `FWDPORT=20000`. Disabled by default. Uncomment to enable.

Internal IPs are `10.100.100.0/24` and `fdfd:100:100::/64`.

## MTProxy (Docker Compose V2)

```
apt-get -y install curl; curl -s https://raw.githubusercontent.com/yurym/deb-prep-tools/main/inst_debian_dckr_mtproxy.sh | bash
```

Default vars: `CLIENTS=1` and `SERVERPORT=443`. Proxy links in `links.txt` file.

## Shadowsocks (Docker Compose V2)

```
apt-get -y install curl; curl -s https://raw.githubusercontent.com/yurym/deb-prep-tools/main/inst_debian_dckr_ss.sh | bash
```

Default vars: `SERVERPORT=8388` and ``PASSWORD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16` ``.