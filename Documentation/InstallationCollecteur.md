# Configuration de la VM Collecteur

## 🚀 Installation Automatique

### Se connecter à la VM
- Connectez-vous à la VM Collecteur avec les identifiants suivants (en QWERTY) :
  - Nom d'utilisateur : `debian`
  - Mot de passe : `debian`

### Passer administrateur 
- Ouvrez un terminal et passez en mode superutilisateur avec la commande `su -` et le mot de passe `debian`


### Cloner le repository
```bash
git clone https://github.com/Ereguof/AnomalyDetect.git
cd AnomalyDetect/Collecteur
```

### Lancer l'installation complète
```bash
chmod +x install.sh
sudo ./install.sh
```

### Démarrer Snort

Dans un terminal, lancer la commande suivante et la garder en route.
```bash
sudo snort -c /etc/snort/snort.conf
```
Cela permet de lancer Snort avec un fichier de configuration spécifique.

## 📊 Configuration Kibana

### 1. Accéder à Kibana
Ouvrez votre navigateur et allez sur : `http://127.0.0.1:5601`

### 2. Créer une Data View
1. **Navigation** : Aller dans `Management` → `Stack management`
2. **Data Views** : Cliquer sur `Data views` dans le menu latéral
3. **Création** : Cliquer sur `Create data view`
4. **Configuration** :
   - **Name** : `snort-logs`
   - **Index pattern** : `filebeat-*`
   - **Time field** : `@timestamp`
5. **Sauvegarde** : Cliquer sur `Save data view to Kibana`

### 3. Visualiser les logs
1. **Navigation** : Aller dans `Analytics` → `Discover`
2. **Sélection** : Choisir la data view `snort-logs`
3. **Affichage** : Cliquer sur le `+` à côté du champ `message` dans `Available fields` pour avoir un meilleur affichage


