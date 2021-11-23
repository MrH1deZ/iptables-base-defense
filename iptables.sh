#!/bin/bash

#####################################
###                               ###
### Script for set firewall rules ###
### Written with love by Mr.H1deZ ###
###                               ###
#####################################

### Vars - You can edit it by your own requirements !
EXT_IF="eth0"
LOCAL_NETS="192.168.0.0/16"
RESTRICTED_NETS="192.168.0.0/24 192.168.1.1"
RESTRICTED_PORTS="22 3306"
PUBLIC_PORTS="80 443 444"

### Options
case $1 in
    show)
        IPT="echo iptables"     # only show, no action
        ;;
    help|?|-h|--help)
        echo "Usage: $0 [show]"
        exit
        ;;
    *)
        IPT="/sbin/iptables"
        ;;
esac

### Flush rules
$IPT --flush
$IPT --delete-chain
$IPT -t nat --flush
$IPT -t filter --flush
$IPT -t nat --delete-chain
$IPT -t filter --delete-chain

### Default rules
$IPT -P INPUT   DROP
$IPT -P OUTPUT  ACCEPT
$IPT -P FORWARD ACCEPT

### Create chains
$IPT -N local_nets
$IPT -N restricted_nets

### Filter rules
## loopback iface
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -d 127.0.0.0/8 -j DROP
$IPT -A INPUT -s 127.0.0.0/8 -j DROP

## ICMP
$IPT -A INPUT -p icmp --icmp-type fragmentation-needed -j DROP
$IPT -A INPUT -p icmp --icmp-type 0 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 3 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 8 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 11 -j ACCEPT

## ESTABLISHED connects
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

## Allow all for local nets
$IPT -A local_nets -j ACCEPT

## Rules for restricted networks
for PORT in $RESTRICTED_PORTS; do
    $IPT -A restricted_nets -p tcp --dport $PORT -j ACCEPT
    $IPT -A restricted_nets -p udp --dport $PORT -j ACCEPT
done

### Chains
## Add ip in local_nets chain
for NET in $LOCAL_NETS; do
    $IPT -A INPUT -s $NET -j local_nets 
done

## Add ip in restricted_nets chain
for NET in $RESTRICTED_NETS; do
    $IPT -A INPUT -s $NET -j restricted_nets
done

### Public ports
if ! [ -z "$PUBLIC_PORTS" ]; then
    for PORT in $PUBLIC_PORTS; do
        $IPT -A INPUT -p tcp --dport $PORT -j ACCEPT
        $IPT -A INPUT -p udp --dport $PORT -j ACCEPT
    done
fi

### Custom rules   - Here you can write something spicy, flexi and sexy !
