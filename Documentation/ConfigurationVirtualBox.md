# Configuration de VirtualBox

Voici les étapes pour configurer VirtualBox afin de simuler le réseau d'entreprise interne nécessaire pour ce projet :

1. Installer VirtualBox (version 7.1.8 utilisée pour ce TP) depuis le site officiel : https://www.virtualbox.org/wiki/Downloads
2. Télécharger l’image ISO de Debian 1.13.0 AMD64 depuis le site officiel : https://www.debian.org
3. Créer 1 machine virtuelle Debian qui servira de modèle pour les 3 machines nécessaires :
   - Ouvrir VirtualBox et cliquer sur "Nouveau"
   - Nommer la VM "Collecteur"
   - Charger l’image ISO de Debian téléchargée précédemment
   - Choisir "Linux" comme type, "Debian" comme subtype et "Debian (64-bit)" comme version
   - Choisir "debian" comme nom d'utilisateur et "debian" comme mot de passe par défaut (par mesure de simplicité pour le TP)
   - Ajouter les Guest Additions
   - Allouer au moins 2048 MB de RAM et 2 CPU
   - Créer un disque dur virtuel de type VDI, dynamiquement alloué, avec une taille d’au moins 20 GB
4. Créer 2 clones de cette VM pour obtenir les 3 machines nécessaires (clic droit sur la VM > "Cloner") et nommez-les respectivement "ServeurWeb" et "Attaquant".
5. Configurer les cartes réseau de chaque VM :
    - Aller dans les paramètres de chaque VM > "Réseau"
    - Activer la carte réseau 1 et choisir "Réseau interne"
    - Nommer le réseau interne (ex : "AnomalyDetectNet") pour que toutes les VM soient sur le même réseau
    - Cocher "Mode Promiscuous" sur "Autoriser tout"
