# Configuration de la VM Attaquant
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

### Aller dans le bon répertoire

Enfin, placez vous dans le répertoire `/root` pour être prêt à lancer les attaques :
  ```bash
    cd /root
  ```