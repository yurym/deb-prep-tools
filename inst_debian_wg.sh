#!/bin/bash
CLIENTS=3
ETHIF=eth0
SERVERIP=`curl -4s icanhazip.com`
SERVERPORT=51194
#SERVERPORTALT=53,51820
#FWDPORT=20000

# --------------------------------------------------
if [ -f /etc/wireguard/wg0_rules.sh ]; then
  systemctl stop wg-quick@wg0.service
  systemctl disable wg-quick@wg0.service
  rm /etc/sysctl.d/wg0.conf
  rm /etc/wireguard/wg0*
  sysctl --system
fi
# --------------------------------------------------
apt-get install -y \
  wireguard wireguard-tools \
  iproute2 iptables traceroute \
  qrencode
# --------------------------------------------------
cat <<EOT > /etc/sysctl.d/wg0.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOT
sysctl --system
# --------------------------------------------------
wg genkey | tee /etc/wireguard/wg0-private-server.key | wg pubkey | tee /etc/wireguard/wg0-public-server.key
for ((i=1;i<=CLIENTS;i++)); do
  wg genkey | tee /etc/wireguard/wg0-private-client$i.key | wg pubkey | tee /etc/wireguard/wg0-public-client$i.key
done
# --------------------------------------------------
iface='$iface'
one='$1'
cat <<EOT > /etc/wireguard/wg0_rules.sh
#!/bin/bash

#-a - add
#-d - del

ipopt () {
iface=$ETHIF
iptables -t nat $one POSTROUTING -o $iface -j MASQUERADE
ip6tables -t nat $one POSTROUTING -o $iface -j MASQUERADE

EOT

if [ -n "$FWDPORT" ]; then
for ((i=1;i<=CLIENTS;i++)); do
port=$(($FWDPORT+$i))
cat <<EOT >> /etc/wireguard/wg0_rules.sh
#client$i port forwarding
iptables -t nat $one PREROUTING -i $iface -p tcp --dport $port -j DNAT --to-destination 10.100.100.$(($i+1)):$port
ip6tables -t nat $one PREROUTING -i $iface -p tcp --dport $port -j DNAT --to-destination [fdfd:100:100::$(($i+1))]:$port
iptables -t nat $one PREROUTING -i $iface -p udp --dport $port -j DNAT --to-destination 10.100.100.$(($i+1)):$port
ip6tables -t nat $one PREROUTING -i $iface -p udp --dport $port -j DNAT --to-destination [fdfd:100:100::$(($i+1))]:$port

EOT
done
fi

if [ -n "$SERVERPORTALT" ]; then
cat <<EOT >> /etc/wireguard/wg0_rules.sh
#multiport input redirect
iptables -t nat $one PREROUTING -i $iface -p udp -m multiport --dports $SERVERPORTALT -j REDIRECT --to-ports $SERVERPORT
ip6tables -t nat $one PREROUTING -i $iface -p udp -m multiport --dports $SERVERPORTALT -j REDIRECT --to-ports $SERVERPORT

EOT
fi

opt='$opt'
asterisk='$*'
cat <<EOT >> /etc/wireguard/wg0_rules.sh
echo "done"
}

if [ -z $asterisk ]
then
echo "No options found!"
exit 1
fi

while getopts ":ad" opt
do
case $opt in
a) echo -n "Adding iptables rules... "; ipopt -A;;
d) echo -n "Deleting iptables rules... "; ipopt -D;;
esac
done
EOT
# --------------------------------------------------
for ((i=1;i<=CLIENTS;i++)); do
cat <<EOT > /etc/wireguard/wg0_qr$i.sh
#!/bin/bash
qrencode -t ansiutf8 < wg0-client$i.conf
EOT
done
# --------------------------------------------------
cat <<EOT > /etc/wireguard/wg0.conf
[Interface]
Address = 10.100.100.1/24,fdfd:100:100::1/64
ListenPort = $SERVERPORT
PrivateKey = `cat /etc/wireguard/wg0-private-server.key`
PostUp = /etc/wireguard/wg0_rules.sh -a
PostDown = /etc/wireguard/wg0_rules.sh -d

EOT

for ((i=1;i<=CLIENTS;i++)); do
cat <<EOT >> /etc/wireguard/wg0.conf
#client$i
[Peer]
PublicKey = `cat /etc/wireguard/wg0-public-client$i.key`
AllowedIPs = 10.100.100.$(($i+1))/32, fdfd:100:100::$(($i+1))/128

EOT

cat <<EOT > /etc/wireguard/wg0-client$i.conf
[Interface]
PrivateKey = `cat /etc/wireguard/wg0-private-client$i.key`
Address = 10.100.100.$(($i+1))/24,fdfd:100:100::$(($i+1))/64
DNS = 1.1.1.1,2606:4700:4700::1111

[Peer]
PublicKey = `cat /etc/wireguard/wg0-public-server.key`
Endpoint = $SERVERIP:$SERVERPORT
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 25
EOT
qrencode -t png -o /etc/wireguard/wg0-client$i.png -r /etc/wireguard/wg0-client$i.conf
done
# --------------------------------------------------
chmod +x /etc/wireguard/wg0*.sh
chmod o-rwx /etc/wireguard/wg0*
# --------------------------------------------------
systemctl start wg-quick@wg0.service && \
  systemctl enable wg-quick@wg0.service && \
  systemctl status wg-quick@wg0.service