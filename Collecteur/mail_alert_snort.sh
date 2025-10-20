#!/bin/bash

LOGFILE="/var/log/snort/snort_syslog.log"
STATEFILE="/tmp/snort_lastline"
SLEEP_INTERVAL=5 

[ ! -f "$STATEFILE" ] && echo 0 > "$STATEFILE"
LASTLINE=$(cat "$STATEFILE")

while true; do
    TOTAL=$(wc -l < "$LOGFILE")
    if [ "$TOTAL" -gt "$LASTLINE" ]; then
        tail -n $((TOTAL-LASTLINE)) "$LOGFILE" | while read -r LINE; do

            echo "$LINE" | mail -s "Nouvelle alerte Snort" debian@localhost
        done
        
        echo "$TOTAL" > "$STATEFILE"
        LASTLINE=$TOTAL
    fi
    
    sleep $SLEEP_INTERVAL
done