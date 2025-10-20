#!/bin/bash

MAILFILE="/var/mail/debian"
LASTSIZE=0
touch $MAILFILE

while true; do
    SIZE=$(stat -c%s "$MAILFILE")
    if [ "$SIZE" -gt "$LASTSIZE" ]; then
        LASTMAIL=$(tail -c $((SIZE - LASTSIZE)) "$MAILFILE")
        SUBJECT=$(echo "$LASTMAIL" | grep -m 1 "^Subject:" | sed 's/^Subject: //')
        notify-send "Nouveau mail" "$SUBJECT"
        play -nq -t alsa synth 0.2 sine 880
        LASTSIZE=$SIZE
    fi
    sleep 5
done
