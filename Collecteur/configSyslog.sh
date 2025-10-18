#!/bin/bash

sudo apt update && apt install -y syslog-ng

# Créer le dossier pour les logs Snort
sudo mkdir -p /var/log/snort
sudo chown root:root /var/log/snort
sudo chmod 750 /var/log/snort

# Créer une nouvelle configuration Syslog-NG dédiée à Snort
cat << 'EOF' > /etc/syslog-ng/conf.d/snort.conf
@version: 3.38

# Source : messages locaux
source s_local {
    system();
    internal();
};

# Destination : fichier spécifique pour Snort
destination d_snort {
    file("/var/log/snort/snort_syslog.log"
         create_dirs(yes)
         owner(root)
         group(root)
         perm(0640));
};

# Filtre pour capturer uniquement la facility LOCAL1
filter f_snort {
    facility(local1);
};

# Liaison source + filtre + destination
log {
    source(s_local);
    filter(f_snort);
    destination(d_snort);
};
EOF

# Démarrer  Syslog-NG
sudo systemctl start syslog-ng
sudo systemctl enable syslog-ng

# Vérifier que le service fonctionne
sudo systemctl is-active --quiet syslog-ng


# Snort peut maintenant envoyer ses alertes vers Syslog-NG avec :
#     output alert_syslog: LOG_LOCAL1 LOG_ALERT
# Les logs seront enregistrés dans :
#     /etc/syslog-ng/conf.d/snort.conf
