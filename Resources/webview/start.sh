#!/bin/bash

CHROME=`type -p google-chrome`
if [ -z "$CHROME" ];then
  CHROME=`type -p chromium`
fi
if [ -z "$CHROME" ];then
  CHROME=`type -p chrome`
fi
if [ -z "$CHROME" ];then
  echo "no google-chromium or chrome found!"
  exit 1
fi

DDIR="$HOME/Library/WebBrowser/Profile"
WDIR="$HOME/Library/WebBrowser/webview.tmp"
PIDF="$HOME/Library/WebBrowser/controller.pid"
LOCK="/tmp/$UID-WebBrowser-controller.lock"

if [ -f "$LOCK" ];then
  echo "lock $LOCK exists, exit"
  exit 1
fi

mkdir -p "$DDIR"
mkdir -p "$WDIR"

cp ./* "$WDIR/"

touch "$DDIR/First Run"
echo "" > "$PIDF"
echo "" > "$LOCK"

cd "$WDIR"
"$CHROME" --user-data-dir=$DDIR --silent-launch --load-and-launch-app=`pwd` "$PIDF"

sleep 5
rm "$LOCK" 2>/dev/null
