#!/bin/bash

CHROME=/snap/bin/chromium
CHROME=/usr/bin/google-chrome
DDIR="$HOME/Library/WebBrowser/Profile"
mkdir -p "$DDIR"

#"$CHROME" --user-data-dir=$DDIR --silent-launch --load-and-launch-app=`pwd`
"$CHROME" --silent-launch --load-and-launch-app=`pwd`
