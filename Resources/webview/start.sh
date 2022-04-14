#!/bin/bash

CHROME=/usr/bin/google-chrome
TDIR="$HOME/.cache/webview.$$"
PFILE="$TDIR/$1.pid"

mkdir "$TDIR"
cp * "$TDIR"

touch "$PFILE"
cd "$TDIR"
"$CHROME" --silent-launch --load-and-launch-app=`pwd` "$PFILE"
sleep 5
rm -R "$TDIR"
