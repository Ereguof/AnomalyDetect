#!/bin/bash
# Script to execute all setup scripts in this folder

bash networkConfig.sh
bash installTools.sh
bash configSnort.sh
bash configSyslog.sh
bash configFilebeat.sh

echo "Installation completed successfully."