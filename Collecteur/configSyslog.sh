#!/bin/bash

set -e 

# Étape 1 : Vérifier si Syslog-NG est installé, sinon l’installer
if ! command -v syslog-ng &> /dev/null; then
    apt update && apt install -y syslog-ng
fi

# Étape 2 : Créer le dossier pour les logs Snort
mkdir -p /var/log/snort
chown syslog:adm /var/log/snort
chmod 750 /var/log/snort

# Étape 3 : Sauvegarder la configuration actuelle de Syslog-NG
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.bak.$(date +%F_%H-%M-%S)

# Étape 4 : Créer une nouvelle configuration Syslog-NG dédiée à Snort
cat << 'EOF' > /etc/syslog-ng/syslog-ng.conf
@version: 3.38
@include "scl.conf"

# Source des logs système
source s_local {
    system();
    internal();
};

# Destination pour les logs Snort
destination d_snort {
    file("/var/log/snort/snort_syslog.log");
};

# Filtre pour isoler les logs Snort (facility local1)
filter f_snort {
    facility(local1);
};

# Chaînage source -> filtre -> destination pour Snort
log {
    source(s_local);
    filter(f_snort);
    destination(d_snort);
};

# Destination par défaut pour les logs système
destination d_messages {
    file("/var/log/messages");
};

# Chaînage standard pour les logs système
log {
    source(s_local);
    destination(d_messages);
};
EOF

# Étape 5 : Redémarrer Syslog-NG pour appliquer la configuration
systemctl restart syslog-ng

# Étape 6 : Vérifier que le service fonctionne
systemctl is-active --quiet syslog-ng


# Snort peut maintenant envoyer ses alertes vers Syslog-NG avec :
#     output alert_syslog: LOG_LOCAL1 LOG_ALERT
# Les logs seront enregistrés dans :
#     /var/log/snort/snort_syslog.log
