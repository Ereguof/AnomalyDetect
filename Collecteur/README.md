# 🔍 VM Collecteur - Guide d'Installation et Configuration

Ce guide détaille l'installation et la configuration complète de la VM Collecteur pour la détection d'anomalies réseau avec Snort, Syslog et intégration ELK Stack.

## 📋 Vue d'ensemble

La VM Collecteur (IP: `10.0.0.2`) surveille le trafic réseau et détecte les anomalies/attaques sur le serveur web (`10.0.0.1`). Elle utilise :

- **Snort** : IDS pour la détection d'intrusions
- **Syslog-ng** : Centralisation des logs
- **Filebeat** : Envoi des logs vers Elasticsearch
- **Kibana** : Visualisation des données

## 🏗️ Architecture

```
VM Attaquant (10.0.0.3) -----> VM Serveur Web (10.0.0.1)
                                        |
                                        v
                               VM Collecteur (10.0.0.2)
                                        |
                                        v
                               ELK Stack (Elasticsearch + Kibana)
```

## ⚙️ Pré-requis

- **OS** : Debian/Ubuntu
- **RAM** : 2GB minimum
- **Réseau** : Interface réseau sur 10.0.0.0/24
- **Privilèges** : Accès sudo

## 🚀 Installation Automatique

### 1. Cloner le repository
```bash
git clone https://github.com/Ereguof/AnomalyDetect.git
cd AnomalyDetect/Collecteur
```

### 2. Lancer l'installation complète
```bash
chmod +x install.sh
sudo ./install.sh
```

Le script `install.sh` exécute automatiquement :
- Configuration réseau (`networkConfig.sh`)
- Installation des outils (`installTools.sh`) 
- Configuration Snort (`configSnort.sh`)
- Configuration Syslog (`configSyslog.sh`)
- Configuration Filebeat (`configFilebeat.sh`)

## 🔧 Installation Manuelle (étape par étape)

### Étape 1 : Configuration Réseau
```bash
sudo ./networkConfig.sh
```
**Actions :**
- Définit le hostname à "Collecteur" 
- Configure l'IP statique `10.0.0.2/24`
- Configure la passerelle par défaut

### Étape 2 : Installation des Outils
```bash
sudo ./installTools.sh
```
**Actions :**
- Nettoie les installations précédentes
- Met à jour le système
- Installe Snort depuis les sources
- Installe syslog-ng
- Installe Filebeat

### Étape 3 : Configuration Snort
```bash
sudo ./configSnort.sh
```
**Actions :**
- Crée les répertoires Snort
- Configure `/etc/snort/snort.conf`
- Crée les règles de détection ICMP dans `/etc/snort/rules/local.rules`

### Étape 4 : Configuration Syslog
```bash
sudo ./configSyslog.sh
```
**Actions :**
- Configure syslog-ng pour recevoir les logs Snort
- Définit les destinations de logs

### Étape 5 : Configuration Filebeat
```bash
sudo ./configFilebeat.sh
```
**Actions :**
- Configure Filebeat pour envoyer les logs vers Elasticsearch
- Active les modules nécessaires

## 🎯 Utilisation de Snort

### Commandes de base
```bash
# Tester la configuration
sudo snort -T -c /etc/snort/snort.conf

# Démarrer Snort en mode interactif
sudo snort -A fast -c /etc/snort/snort.conf -l /var/log/snort -i eth0

# Démarrer en mode daemon
sudo snort -D -A fast -c /etc/snort/snort.conf -l /var/log/snort -i eth0

# Voir les alertes en temps réel
tail -f /var/log/snort/alert

# Arrêter Snort
sudo pkill snort
```

### Tests de fonctionnement
```bash
# Test ping (doit générer des alertes ICMP)
ping -c 3 8.8.8.8

# Vérifier les alertes
cat /var/log/snort/alert
```

## 📊 Configuration Kibana

### 1. Accéder à Kibana
Ouvrez votre navigateur et allez sur : `http://KIBANA_IP:5601`

### 2. Créer une Data View
1. **Navigation** : Aller dans `Management` → `Stack management`
2. **Data Views** : Cliquer sur `Data views` dans le menu latéral
3. **Création** : Cliquer sur `Create data view`
4. **Configuration** :
   - **Name** : `snort-logs`
   - **Index pattern** : `snort-*` ou `filebeat-*`
   - **Time field** : `@timestamp`
5. **Sauvegarde** : Cliquer sur `Save data view to Kibana`

### 3. Visualiser les logs
1. **Navigation** : Aller dans `Analytics` → `Discover`
2. **Sélection** : Choisir la data view `snort-logs`
3. **Affichage** : Cliquer sur le `+` à côté du champ `message` dans `Available fields`

### 4. Filtres utiles
```
# Alertes ICMP uniquement
message: "ICMP"

# Alertes par niveau de sévérité
level: "alert" OR level: "warning"

# Filtrer par période
@timestamp: [now-1h TO now]
```

## 📁 Structure des Fichiers

```
Collecteur/
├── README.md                 # Ce guide
├── install.sh               # Installation automatique
├── networkConfig.sh         # Configuration réseau
├── installTools.sh          # Installation Snort/Syslog/Filebeat
├── configSnort.sh           # Configuration Snort
├── configSyslog.sh          # Configuration Syslog-ng
└── configFilebeat.sh        # Configuration Filebeat
```

## 🔍 Règles de Détection Snort

### Règles ICMP actuelles
```bash
# Détection des requêtes ping
alert icmp any any -> any any (msg:"ICMP Ping Request détecté"; itype:8; sid:1000001; rev:1;)

# Détection des réponses ping  
alert icmp any any -> any any (msg:"ICMP Ping Reply détecté"; itype:0; sid:1000002; rev:1;)

# Log général ICMP
alert icmp any any -> any any (msg:"Tout trafic ICMP détecté"; sid:1000003; rev:1;)
```

### Ajout de nouvelles règles
Éditer le fichier : `/etc/snort/rules/local.rules`
```bash
sudo nano /etc/snort/rules/local.rules
```

## 📝 Logs et Monitoring

### Emplacements des logs
```
/var/log/snort/alert          # Alertes Snort
/var/log/snort/snort.log      # Logs détaillés Snort
/var/log/syslog              # Logs système
/var/log/filebeat/           # Logs Filebeat
```

### Surveillance en temps réel
```bash
# Surveiller les alertes Snort
tail -f /var/log/snort/alert

# Surveiller tous les logs système
tail -f /var/log/syslog

# Vérifier le statut Filebeat
sudo systemctl status filebeat

# Logs Filebeat
sudo journalctl -u filebeat -f
```

## 🚨 Dépannage

### Problèmes courants

**1. Snort ne démarre pas**
```bash
# Vérifier la configuration
sudo snort -T -c /etc/snort/snort.conf

# Vérifier les permissions
sudo chown -R snort:snort /var/log/snort
```

**2. Pas d'alertes générées**
```bash
# Vérifier l'interface réseau
ip a

# Tester avec une interface spécifique
sudo snort -A fast -c /etc/snort/snort.conf -l /var/log/snort -i enp0s8 -v
```

**3. Filebeat ne se connecte pas à Elasticsearch**
```bash
# Vérifier la configuration
sudo filebeat test config

# Tester la connexion
sudo filebeat test output
```

**4. Kibana n'affiche pas les données**
- Vérifier que l'index pattern correspond aux données envoyées
- Vérifier les timestamps (décalage horaire)
- Contrôler les filtres de temps dans Kibana

### Commandes de diagnostic
```bash
# Statut des services
sudo systemctl status snort
sudo systemctl status syslog-ng  
sudo systemctl status filebeat

# Processus actifs
ps aux | grep snort
ps aux | grep filebeat

# Utilisation réseau
sudo netstat -tulpn | grep :514  # Syslog
sudo netstat -tulpn | grep :9200 # Elasticsearch
```

## 📞 Support

Pour des problèmes spécifiques :
1. Vérifier les logs d'erreur dans `/var/log/`
2. Consulter la documentation officielle Snort
3. Vérifier la connectivité réseau entre les composants
4. S'assurer que les services sont démarrés et actifs

## 🏷️ Version

- **Snort** : Version compilée depuis les sources
- **Syslog-ng** : Version repository Debian
- **Filebeat** : Dernière version Elastic
- **Système** : Compatible Debian/Ubuntu

---

**Note** : Ce guide suppose une installation sur un réseau `10.0.0.0/24`. Adaptez les adresses IP selon votre environnement.