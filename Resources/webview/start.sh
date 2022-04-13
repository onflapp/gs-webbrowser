#!/bin/bash

PFILE="$HOME/.cache/webview.$$.$1.pid"
touch $PFILE
chromium --silent-launch --load-and-launch-app=`pwd` "$PFILE"
sleep 3
rm $PFILE
