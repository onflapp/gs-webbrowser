#!/bin/bash

CHROME=/snap/bin/chromium
CHROME=/usr/bin/google-chrome
DDIR="$HOME/Library/WebBrowser/Profile"
PIDF="$HOME/Library/WebBrowser/controller.pid"
mkdir -p "$DDIR"

touch "$DDIR/First Run"
echo "" > "$PIDF"

"$CHROME" --user-data-dir=$DDIR --silent-launch --load-and-launch-app=`pwd` "$PIDF"
