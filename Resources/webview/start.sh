#!/bin/bash

CHROME=/usr/bin/google-chrome
CHROME=/snap/bin/chromium
TDIR="$HOME/Library/WebBrowser/webview.$$"
PFILE="$TDIR/$1.pid"

mkdir -p "$TDIR"
cp * "$TDIR"

touch "$PFILE"
cd "$TDIR"
"$CHROME" --silent-launch --load-and-launch-app=`pwd` "$PFILE"
sleep 5
rm -R "$TDIR"
