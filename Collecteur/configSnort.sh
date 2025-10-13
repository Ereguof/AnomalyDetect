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
# Configuration Snort pour la détection d'anomalies - VM Collecteur (10.0.0.2)
# Variables de réseau spécifiques à l'environnement
var HOME_NET 10.0.0.0/24
var EXTERNAL_NET !$HOME_NET
var WEB_SERVER 10.0.0.1
var COLLECTEUR 10.0.0.2
var ATTACKER_NET 10.0.0.3
var RULE_PATH /etc/snort/rules
var SO_RULE_PATH /etc/snort/so_rules
var PREPROC_RULE_PATH /etc/snort/preproc_rules

# Ports de services critiques
var HTTP_PORTS 80
var SSH_PORTS 22
var SQL_PORTS 3306

# Configurer le chemin vers les bibliothèques dynamiques
dynamicpreprocessor directory /usr/local/lib/snort_dynamicpreprocessor/
dynamicengine directory /usr/local/lib/snort_dynamicengine/
dynamicdetection directory /usr/local/lib/snort_dynamicrules/

# Configuration des préprocesseurs
preprocessor frag3_global: max_frags 65536
preprocessor frag3_engine: policy windows detect_anomalies overlap_limit 10 min_fragment_length 100 timeout 180

# Stream5
preprocessor stream5_global: track_tcp yes, track_udp yes, track_icmp yes, max_tcp 262144, max_udp 131072, max_active_responses 2, min_response_seconds 5
preprocessor stream5_tcp: policy windows, detect_anomalies, require_3whs 180, overlap_limit 10, small_segments 3 bytes 150, timeout 180, ports client 21 22 23 25 42 53 79 109 110 111 113 119 135 136 137 139 143 161 445 993 995 1433 1521 2100 3306 6665 6666 6667 6668 6669 7000 32770 32771 32772 32773 32774 32775 32776 32777 32778 32779, ports both 80 311 443 465 563 591 636 901 989 992 994 995 1220 1414 1830 2301 2381 2809 3128 3702 7907 7001 7802 7777 7779 7801 7900 7901 7902 7903 7904 7905 7906 9090 9091 9443 9999 11371
preprocessor stream5_udp: timeout 180
preprocessor stream5_icmp: timeout 30

# Configuration de sortie
output alert_fast: alerts.txt
output log_tcpdump: snort.log
output alert_syslog: LOG_LOCAL1 LOG_ALERT

# Inclusion des règles
include $RULE_PATH/local.rules
EOF

# Configuration des règles pour capturer les pings ICMP
sudo tee /etc/snort/rules/local.rules > /dev/null << 'EOF'
# ================================================================================================
# RÈGLES DE DÉTECTION ICMP/PING - VM Collecteur (10.0.0.2)
# ================================================================================================

# ===== RÈGLES ICMP (détection des pings) =====
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Request détecté"; itype:8; sid:1000001; rev:1;)
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Reply détecté"; itype:0; sid:1000002; rev:1;)
log icmp any any -> any any (msg:"Trafic ICMP logged"; sid:1000003; rev:1;)
EOF

echo "Configuration Snort terminée"
echo "Démarrer Snort: sudo snort -A fast -c /etc/snort/snort.conf -l /var/log/snort -i INTERFACE"
echo "Voir alertes: tail -f /var/log/snort/alert"
echo "Arrêter: sudo pkill snort"
