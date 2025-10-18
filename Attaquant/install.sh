#!/bin/bash
# Script to execute both installTools.sh and networkConfig.sh in this folder

set -e

bash networkConfig.sh
bash installTools.sh
echo "Installation completed successfully."
