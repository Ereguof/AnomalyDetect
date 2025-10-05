#!/bin/bash
# Script to execute all setup scripts in this folder

set -e

bash installTools.sh
bash networkConfig.sh
bash configSnort.sh

echo "Installation completed successfully."