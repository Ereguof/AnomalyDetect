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

# Inclusion des règles
include $RULE_PATH/local.rules
EOF

# Configuration des règles pour capturer les pings ICMP
sudo tee /etc/snort/rules/local.rules > /dev/null << 'EOF'
# ================================================================================================
# RÈGLES DE DÉTECTION D'ATTAQUES - VM Collecteur (10.0.0.2) surveillant Serveur Web (10.0.0.1)
# ================================================================================================

# ===== ATTAQUE 1 - SCAN DE PORTS (NMAP) =====
# Détection de scan de ports TCP (nmap classique)
alert tcp any any -> $WEB_SERVER any (msg:"[ATTAQUE 1] Port Scan TCP détecté vers serveur web"; flags:S; threshold:type both, track by_src, count 5, seconds 10; sid:2000001; rev:1; classtype:attempted-recon;)

# Détection de scan SYN (nmap -sS)
alert tcp any any -> $WEB_SERVER any (msg:"[ATTAQUE 1] SYN Scan détecté vers serveur web"; flags:S,!A; threshold:type both, track by_src, count 10, seconds 15; sid:2000002; rev:1; classtype:attempted-recon;)

# Détection de scan UDP (nmap -sU)
alert udp any any -> $WEB_SERVER any (msg:"[ATTAQUE 1] UDP Scan détecté vers serveur web"; threshold:type both, track by_src, count 5, seconds 10; sid:2000003; rev:1; classtype:attempted-recon;)

# Détection de scan XMAS et NULL (techniques furtives nmap)
alert tcp any any -> $WEB_SERVER any (msg:"[ATTAQUE 1] XMAS Scan détecté"; flags:FPU; sid:2000004; rev:1; classtype:attempted-recon;)
alert tcp any any -> $WEB_SERVER any (msg:"[ATTAQUE 1] NULL Scan détecté"; flags:0; sid:2000005; rev:1; classtype:attempted-recon;)

# ===== ATTAQUE 2 - INJECTION SQL =====
# Détection d'injection SQL basique dans les requêtes HTTP
alert tcp any any -> $WEB_SERVER $HTTP_PORTS (msg:"[ATTAQUE 2] Tentative d'injection SQL détectée"; flow:to_server,established; content:"GET"; http_method; content:"or 1=1"; http_uri; nocase; sid:2000006; rev:1; classtype:web-application-attack;)

alert tcp any any -> $WEB_SERVER $HTTP_PORTS (msg:"[ATTAQUE 2] Injection SQL - Union Select"; flow:to_server,established; content:"union"; http_uri; nocase; content:"select"; http_uri; nocase; distance:0; within:20; sid:2000007; rev:1; classtype:web-application-attack;)

alert tcp any any -> $WEB_SERVER $HTTP_PORTS (msg:"[ATTAQUE 2] Injection SQL - Caractères suspects"; flow:to_server,established; content:"'"; http_uri; pcre:"/(\%27)|(\')|(--)|(\%2D\%2D)|(\%23)|(\#)/i"; sid:2000008; rev:1; classtype:web-application-attack;)

# Détection spécifique pour ' or 1=1#
alert tcp any any -> $WEB_SERVER $HTTP_PORTS (msg:"[ATTAQUE 2] Injection SQL classique détectée"; flow:to_server,established; content:"or"; http_uri; nocase; content:"1=1"; http_uri; nocase; distance:0; within:10; sid:2000009; rev:1; classtype:web-application-attack;)

# ===== ATTAQUE 3 - BRUTE FORCE SSH =====
# Détection de tentatives de connexion SSH multiples (Hydra)
alert tcp any any -> $WEB_SERVER $SSH_PORTS (msg:"[ATTAQUE 3] Brute Force SSH détecté"; flow:to_server,established; content:"SSH"; depth:4; threshold:type both, track by_src, count 10, seconds 60; sid:2000010; rev:1; classtype:attempted-user;)

# Détection de multiples échecs de connexion SSH
alert tcp any any -> $WEB_SERVER $SSH_PORTS (msg:"[ATTAQUE 3] Échecs multiples connexion SSH"; flow:to_server,established; threshold:type both, track by_src, count 5, seconds 30; sid:2000011; rev:1; classtype:attempted-user;)

# Détection de pattern Hydra spécifique
alert tcp any any -> $WEB_SERVER $SSH_PORTS (msg:"[ATTAQUE 3] Activité Hydra SSH suspectée"; flow:to_server,established; content:"SSH-2.0"; depth:20; threshold:type both, track by_src, count 15, seconds 120; sid:2000012; rev:1; classtype:attempted-user;)

# ===== ATTAQUE 4 - ESCALADE DE PRIVILÈGES =====
# Détection de commandes sudo suspectes (difficile via réseau, mais on peut détecter des patterns)
alert tcp $WEB_SERVER any -> any any (msg:"[ATTAQUE 4] Activité administrative suspecte détectée"; flow:from_server,established; content:"sudo"; sid:2000013; rev:1; classtype:suspicious-login;)

# Détection de shells privilégiés (connexions root sortantes)
alert tcp $WEB_SERVER any -> any any (msg:"[ATTAQUE 4] Shell privilégié détecté"; flow:from_server,established; content:"root"; sid:2000014; rev:1; classtype:suspicious-login;)

# ===== ATTAQUE 5 - EXFILTRATION DE DONNÉES =====
# Détection de transferts SCP sortants depuis le serveur
alert tcp $WEB_SERVER any -> any $SSH_PORTS (msg:"[ATTAQUE 5] Exfiltration SCP détectée depuis serveur"; flow:to_server,established; content:"scp"; sid:2000015; rev:1; classtype:policy-violation;)

# Détection de gros transferts de données sortants
alert tcp $WEB_SERVER any -> any any (msg:"[ATTAQUE 5] Transfert volumineux sortant détecté"; flow:from_server,established; dsize:>10000; threshold:type limit, track by_src, count 1, seconds 10; sid:2000016; rev:1; classtype:policy-violation;)

# Détection de connexions SSH sortantes depuis le serveur (inhabituel)
alert tcp $WEB_SERVER any -> any $SSH_PORTS (msg:"[ATTAQUE 5] Connexion SSH sortante depuis serveur"; flow:to_server,established; flags:S; sid:2000017; rev:1; classtype:policy-violation;)

# Détection spécifique pour fichiers .jpg (exfiltration d'images)
alert tcp $WEB_SERVER any -> any any (msg:"[ATTAQUE 5] Exfiltration possible de fichier image"; flow:from_server,established; content:".jpg"; nocase; sid:2000018; rev:1; classtype:policy-violation;)

# ===== RÈGLES GÉNÉRALES DE SURVEILLANCE =====
# Surveillance générale du trafic vers/depuis le serveur web
log tcp any any -> $WEB_SERVER any (msg:"Trafic TCP vers serveur web"; sid:2000019; rev:1;)
log tcp $WEB_SERVER any -> any any (msg:"Trafic TCP depuis serveur web"; sid:2000020; rev:1;)

# Surveillance des connexions HTTP
alert tcp any any -> $WEB_SERVER $HTTP_PORTS (msg:"Connexion HTTP vers serveur web"; flow:to_server,established; sid:2000021; rev:1; classtype:misc-activity;)

# Surveillance des connexions SSH
alert tcp any any -> $WEB_SERVER $SSH_PORTS (msg:"Connexion SSH vers serveur web"; flow:to_server,established; flags:S; sid:2000022; rev:1; classtype:misc-activity;)

# ===== RÈGLES ICMP (conservation des règles ping originales) =====
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Request détecté"; itype:8; sid:2000023; rev:1;)
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Reply détecté"; itype:0; sid:2000024; rev:1;)
log icmp any any -> any any (msg:"Trafic ICMP logged"; sid:2000025; rev:1;)
EOF

# Création d'un script de démarrage pour Snort
sudo tee /etc/snort/start_snort.sh > /dev/null << 'EOF'
#!/bin/bash
# Script pour démarrer Snort - VM Collecteur (10.0.0.2)

INTERFACE=$(ip route | grep "10.0.0.0/24" | awk '{print $3}' | head -n1)

if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
fi

echo "Démarrage Snort sur interface: $INTERFACE"
echo "Surveillance réseau: 10.0.0.0/24"
echo "Serveur cible: 10.0.0.1"

sudo mkdir -p /var/log/snort
sudo snort -D -i $INTERFACE -c /etc/snort/snort.conf -l /var/log/snort -A fast -q

if [ $? -eq 0 ]; then
    echo "Snort démarré"
    echo "Alertes: tail -f /var/log/snort/alert"
    echo "Arrêt: sudo pkill snort"
else
    echo "Erreur démarrage Snort"
fi
EOF

sudo chmod +x /etc/snort/start_snort.sh

# Création d'un script pour tester la configuration
sudo tee /etc/snort/test_snort.sh > /dev/null << 'EOF'
#!/bin/bash
# Script pour tester la configuration Snort

echo "Test configuration Snort..."
sudo snort -T -c /etc/snort/snort.conf

if [ $? -eq 0 ]; then
    echo "Configuration valide"
    echo "Démarrer: sudo /etc/snort/start_snort.sh"
    echo "Alertes: tail -f /var/log/snort/alert"
    echo "Arrêter: sudo pkill snort"
else
    echo "Erreur configuration"
fi
EOF

sudo chmod +x /etc/snort/test_snort.sh

# Création d'un script de monitoring des attaques
sudo tee /etc/snort/monitor_attacks.sh > /dev/null << 'EOF'
#!/bin/bash
# Script de monitoring des attaques

if ! pgrep snort > /dev/null; then
    echo "Snort non actif"
    echo "Démarrer avec: sudo /etc/snort/start_snort.sh"
    exit 1
fi

echo "Monitoring Snort actif"
echo "Ctrl+C pour arrêter"

tail -f /var/log/snort/alert | while read line; do
    timestamp=$(date '+%H:%M:%S')
    
    if echo "$line" | grep -q "ATTAQUE 1"; then
        echo "[$timestamp] SCAN PORTS: $line"
    elif echo "$line" | grep -q "ATTAQUE 2"; then
        echo "[$timestamp] INJECTION SQL: $line"
    elif echo "$line" | grep -q "ATTAQUE 3"; then
        echo "[$timestamp] BRUTE FORCE: $line"
    elif echo "$line" | grep -q "ATTAQUE 4"; then
        echo "[$timestamp] ESCALADE: $line"
    elif echo "$line" | grep -q "ATTAQUE 5"; then
        echo "[$timestamp] EXFILTRATION: $line"
    else
        echo "[$timestamp] $line"
    fi
done
EOF

sudo chmod +x /etc/snort/monitor_attacks.sh

echo "Configuration Snort terminée"
echo "Test: sudo /etc/snort/test_snort.sh"
echo "Démarrage: sudo /etc/snort/start_snort.sh"
echo "Monitoring: sudo /etc/snort/monitor_attacks.sh"
