#!/bin/bash

CHROME=/usr/bin/google-chrome
CHROME=/snap/bin/chromium
DDIR="$HOME/Library/WebBrowser/Profile"
PIDF="$HOME/Library/WebBrowser/controller.pid"
mkdir -p "$DDIR"

touch "$DDIR/First Run"
echo "" > "$PIDF"

"$CHROME" --user-data-dir=$DDIR --silent-launch --load-and-launch-app=`pwd` "$PIDF"
