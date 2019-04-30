#!/bin/bash
# Usage: apt-toggle (on|off)

# Allowed hosts (!CHANGE-MANUALLY)
ips=(
    88.221.72.98
    95.100.178.97
    128.31.0.63
    130.235.34.30
    137.254.60.34
    151.101.16.204
    151.101.60.204
    151.101.84.204
    151.101.184.204
    194.71.11.173
    194.71.11.165
    194.71.11.137
    194.71.11.138
    194.71.11.142
    194.71.11.173
    194.71.11.176
    212.211.132.250
    217.196.149.233
)

option=$1

if [[ "${option}" == "on" ]] ;
then
    echo "[+] Adding exceptions in firewall"
    echo "  [+] Adding exception for DNS"
    iptables -I EXCEPTIONS_OUT -p udp --dport 53 --sport 1024:65535 -j ACCEPT
    iptables -I EXCEPTIONS_IN -p udp --sport 53 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
    for ip in ${ips[@]}
    do
        echo "  [+] Adding exception for: ${ip}:80/443"
        iptables -I EXCEPTIONS_OUT -p tcp --dport 80 --sport 1024:65535 -d ${ip}/32 -j ACCEPT
        iptables -I EXCEPTIONS_OUT -p tcp --dport 443 --sport 1024:65535 -d ${ip}/32 -j ACCEPT
        iptables -I EXCEPTIONS_IN -p tcp --sport 80 --dport 1024:65535 -s ${ip}/32 -m state --state ESTABLISHED -j ACCEPT
        iptables -I EXCEPTIONS_IN -p tcp --sport 443 --dport 1024:65535 -s ${ip}/32 -m state --state ESTABLISHED -j ACCEPT
    done
else
    echo "[+] Flushing exceptions from firewall"
    iptables-restore < /etc/iptables/rules.v4
fi
