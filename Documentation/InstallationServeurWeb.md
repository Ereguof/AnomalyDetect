# Configuration de la VM Serveur Web

- Connectez-vous à la VM Serveur Web avec les identifiants suivants (en QWERTY) :
  - Nom d'utilisateur : `debian`
  - Mot de passe : `debian`

- Ouvrez un terminal et passez en mode superutilisateur avec la commande `su -` et le mot de passe `debian`

- Clonez le dépôt GitHub contenant les scripts d'installation :
  ```bash
    git clone https://github.com/Ereguof/AnomalyDetect.git
    cd AnomalyDetect/ServeurWeb
    ```

- Exécutez le script d'installation :
    ```bash
        bash install.sh
     ```

