# Alertes par Mail

Pour cette partie bonus, nous avons créé un petit système d'alertes par mail, fonctionnant sans internet après installation des paquets pour les besoins du TP.
L'utilisateur qui reçoit les mails est "debian".

Pour que les scripts fonctionnent, il est nécessaire d’installer quelques paquets :  

```
sudo apt install postfix mailutils libnotify-bin sox -y
```

Pour postfix, lors de la configuration vous devrez choisir "Internet Site"

Le premier script **alert.sh** permet de créer une petite alerte visuelle et sonore lorsqu'un mail est reçu.
On pourra le lancer avec `bash /root/AnomalyDetect/Collecteur/alert.sh &` pour le faire tourner en arrière plan ou le lancer au démarrage de la machine via le systemd ou crontab :


Voici un deuxième script **mail_alert_snort.sh** qui envoie un mail à debian en cas de nouvelle ligne de log faite par snort : `bash /root/AnomalyDetect/Collecteur/mail_alert_snort.sh &`
