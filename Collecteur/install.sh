#!/bin/bash
# Script to execute all setup scripts in this folder

set -e

bash networkConfig.sh
bash installTools.sh
bash configSnort.sh
bash configSyslog.sh

echo "Installation completed successfully."