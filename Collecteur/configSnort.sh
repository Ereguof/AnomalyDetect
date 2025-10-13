#!/bin/bash
# Script to configure Snort on the Collecteur VM

#Creation of snort user and group

sudo mkdir -p /etc/snort/rules
sudo mkdir -p /etc/snort/preproc_rules
sudo mkdir -p /var/log/snort
sudo mkdir -p /usr/local/lib/snort_dynamicrules
sudo touch /etc/snort/snort.conf
sudo touch /etc/snort/rules/local.rules
sudo chown -R snort:snort /var/log/snort
sudo chmod -R 5775 /var/log/snort

# Configuration de base de snort.conf
sudo tee /etc/snort/snort.conf > /dev/null << 'EOF'
# Chemins var RULE_PATH /etc/snort/rules
var SO_RULE_PATH /etc/snort/so_rules 
var PREPROC_RULE_PATH /etc/snort/preproc_rules 
var WHITE_LIST_PATH /etc/snort/rules 
var BLACK_LIST_PATH /etc/snort/rules 
# Réseaux
var HOME_NET any
var EXTERNAL_NET any
# Préprocesseurs
preprocessor stream5_global: track_tcp yes, track_udp yes, track_icmp yes
preprocessor stream5_tcp: policy first, detect_anomalies
preprocessor stream5_udp: timeout 30
preprocessor stream5_icmp: timeout 30
preprocessor frag3_global: max_frags 65536
preprocessor frag3_engine: policy linux detect_anomalies
# Sortie (Outputs)
# Envoie les alertes vers Syslog-NG (facility local1, priority ALERT)
output alert_syslog: LOG_LOCAL1 LOG_ALERT
# Pour console (optionnel)
# output alert_console
#Inclusion des règles
include $RULE_PATH/local.rules
EOF

# Configuration des règles pour capturer les pings ICMP
sudo tee /etc/snort/rules/local.rules > /dev/null << 'EOF'
# Détection
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Request détecté"; itype:8; sid:1000001; rev:1;)
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Reply détecté"; itype:0; sid:1000002; rev:1;)
log icmp any any -> any any (msg:"Trafic ICMP logged"; sid:1000003; rev:1;)

# local.rules - détections ciblées pour TP
# 1) Scan HTTP User-Agent Nmap
alert tcp any any -> any 80 (msg:"SCAN - HTTP User-Agent contains Nmap"; content:"User-Agent" ; http_header; content:"Nmap" ; http_header; nocase; sid:1000001; rev:1;)

# 2) SYN flood / many SYNs (port scanning)
alert tcp any any -> any any (msg:"SCAN - many SYNs from same src"; flags:S; threshold:type limit, track by_src, count 20, seconds 10; sid:1000002; rev:1;)

# 3) SQLi - OR 1=1 in client body
alert tcp any any -> any 80 (msg:"SQLi - pattern OR 1=1"; flow:to_server,established; content:"or 1=1"; nocase; http_client_body; sid:1000010; rev:1;)

alert tcp any any -> any 80 (msg:"SQLi - simple OR 1=1 in POST body"; flow:to_server,established; content:"or 1=1"; nocase; http_client_body; sid:1001010; rev:1;)

alert tcp any any -> any 80 (msg:"SQLi - OR 1=1 in URI"; flow:to_server,established; uricontent:"or 1=1"; nocase; sid:1001011; rev:1;)

# 4) SQLi - UNION SELECT in URI
alert tcp any any -> any 80 (msg:"SQLi - UNION SELECT in URI"; flow:to_server,established; content:"union"; nocase; content:"select"; nocase; http_uri; sid:1000011; rev:1;)

# 5) SSH connection attempt (each new session to port 22)
#alert tcp any any -> any 22 (msg:"SSH - connection attempt"; flow:to_server,established; sid:1000020; rev:1;)

# 6) SSH brute-force - many connections from same src to port 22
alert tcp any any -> any 22 (msg:"SSH - possible brute force (many conn attempts)"; flags:S; threshold:type limit, track by_src, count 10, seconds 60; sid:1000021; rev:1;)

# 7) Outbound SSH session started from internal host (to detect exfil attempt)
#alert tcp any any -> any 22 (msg:"Outbound SSH from internal host"; flow:established,to_server; sid:1000030; rev:1;)

alert tcp any any -> any 22 (msg:"SSH brute/exfil heuristic - many packets to SSH"; flags:PA; threshold:type both, track by_src, count 10 , seconds 300; sid:1001031; rev:1;)

EOF

echo "Configuration Snort terminée"
echo "Démarrer Snort: sudo snort -A fast -c /etc/snort/snort.conf -l /var/log/snort -i INTERFACE"
echo "Voir alertes: tail -f /var/log/snort/alert"
echo "Arrêter: sudo pkill snort"
