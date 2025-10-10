#!/bin/bash
# Script to configure Snort on the Collecteur VM

#Creation of snort user and group

sudo mkdir -p /etc/snort/rules
sudo mkdir -p /etc/snort/preproc_rules
sudo mkdir -p /var/log/snort
sudo mkdir -p /usr/local/lib/snort_dynamicrules
sudo touch /etc/snort/snort.conf
sudo touch /etc/snort/rules/local.rules
sudo chown -R snort:snort /var/log/snort
sudo chmod -R 5775 /var/log/snort
