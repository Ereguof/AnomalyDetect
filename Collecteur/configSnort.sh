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
# Configuration Snort pour la détection d'anomalies
# Variables de réseau
var HOME_NET any
var EXTERNAL_NET any
var RULE_PATH /etc/snort/rules
var SO_RULE_PATH /etc/snort/so_rules
var PREPROC_RULE_PATH /etc/snort/preproc_rules

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

# Inclusion des règles
include $RULE_PATH/local.rules
EOF

# Configuration des règles pour capturer les pings ICMP
sudo tee /etc/snort/rules/local.rules > /dev/null << 'EOF'
# Règles pour la détection des pings ICMP
# Alerte sur les requêtes ping (ICMP Echo Request)
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Request Detected"; itype:8; sid:1000001; rev:1;)

# Alerte sur les réponses ping (ICMP Echo Reply)
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Reply Detected"; itype:0; sid:1000002; rev:1;)

# Log de tous les paquets ICMP pour analyse détaillée
log icmp any any -> any any (msg:"ICMP Traffic Logged"; sid:1000003; rev:1;)

# Détection de ping flood (nombreuses requêtes ICMP)
alert icmp any any -> $HOME_NET any (msg:"Possible ICMP Flood Attack"; itype:8; threshold:type both, track by_src, count 10, seconds 5; sid:1000004; rev:1;)

# Détection de pings de taille inhabituelle (potentiel ping of death)
alert icmp any any -> $HOME_NET any (msg:"Large ICMP Packet Detected"; itype:8; dsize:>1000; sid:1000005; rev:1;)
EOF

# Création d'un script de démarrage pour Snort
sudo tee /etc/snort/start_snort.sh > /dev/null << 'EOF'
#!/bin/bash
# Script pour démarrer Snort en mode de capture ICMP

# Déterminer l'interface réseau (adapter selon votre configuration)
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

echo "Démarrage de Snort sur l'interface: $INTERFACE"
echo "Logs sauvegardés dans: /var/log/snort/"

# Démarrer Snort en mode daemon avec logging
sudo snort -D -i $INTERFACE -c /etc/snort/snort.conf -l /var/log/snort -A fast

echo "Snort démarré. Utilisez 'sudo pkill snort' pour l'arrêter."
echo "Pour voir les alertes en temps réel: tail -f /var/log/snort/alerts.txt"
EOF

sudo chmod +x /etc/snort/start_snort.sh

# Création d'un script pour tester la configuration
sudo tee /etc/snort/test_snort.sh > /dev/null << 'EOF'
#!/bin/bash
# Script pour tester la configuration Snort

echo "Test de la configuration Snort..."
sudo snort -T -c /etc/snort/snort.conf

if [ $? -eq 0 ]; then
    echo "Configuration Snort valide !"
    echo "Pour démarrer Snort: sudo /etc/snort/start_snort.sh"
    echo "Pour tester la capture de ping: ping -c 3 8.8.8.8"
    echo "Pour voir les logs: tail -f /var/log/snort/alerts.txt"
else
    echo "Erreur dans la configuration Snort. Veuillez vérifier les fichiers."
fi
EOF

sudo chmod +x /etc/snort/test_snort.sh

echo "Configuration Snort terminée !"
echo "Utilisez 'sudo /etc/snort/test_snort.sh' pour tester la configuration"
echo "Utilisez 'sudo /etc/snort/start_snort.sh' pour démarrer Snort"
