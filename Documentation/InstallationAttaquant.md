# Configuration de la VM Attaquant

- Connectez-vous à la VM Attaquant avec les identifiants suivants (en QWERTY) :
  - Nom d'utilisateur : `debian`
  - Mot de passe : `debian`

- Ouvrez un terminal et passez en mode superutilisateur avec la commande `su -` et le mot de passe `debian`

- Clonez le dépôt GitHub contenant les scripts d'installation :
  ```bash
    git clone https://github.com/Ereguof/AnomalyDetect.git
    cd AnomalyDetect/Attaquant
    ```

- Exécutez le script d'installation :
    ```bash
        bash install.sh
     ```

- Enfin, placez vous dans le répertoire `/root` pour être prêt à lancer les attaques :
  ```bash
    cd /root
    ```