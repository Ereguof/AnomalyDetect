#!/bin/bash
# Script to execute both installTools.sh and networkConfig.sh in this folder

set -e

# Execute installTools.sh
bash installTools.sh

# Execute networkConfig.sh
bash networkConfig.sh

echo "Installation completed successfully."