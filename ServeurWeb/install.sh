#!/bin/bash
# Script to execute both installServer.sh and networkConfig.sh in this folder

set -e

bash installServer.sh
bash networkConfig.sh

echo "Installation completed successfully."