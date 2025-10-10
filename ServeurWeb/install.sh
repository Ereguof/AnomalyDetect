#!/bin/bash
# Script to execute both installServer.sh and networkConfig.sh in this folder

set -e

bash networkConfig.sh
bash installServer.sh

echo "Installation completed successfully."