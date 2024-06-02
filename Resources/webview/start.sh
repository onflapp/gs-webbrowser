#!/bin/bash

function cleanup {
  rm "$LOCK" 2>/dev/null
  exit 0
}

trap cleanup SIGINT SIGTERM

APPNAME="$1"
CHROME=`type -p google-chrome`
[ -z "$CHROME" ] && CHROME=`type -p chromium`
[ -z "$CHROME" ] && CHROME=`type -p chromium-browser`
[ -z "$CHROME" ] && CHROME=`type -p chrome`

if [ -z "$CHROME" ];then
  echo "no google-chrome|chromium|chromium-browser|chrome found!"
  exit 10
fi

#ARGS="--disable-smooth-scrolling"
DDIR="$HOME/Library/$APPNAME/Profile"
WDIR="$HOME/Library/$APPNAME/webview.tmp"
PIDF="$HOME/Library/$APPNAME/controller.pid"
LOCK="/tmp/$UID-$APPNAME-controller.lock"

if [ -f "$LOCK" ];then
  echo "lock $LOCK exists, exit"
  exit 1
fi

mkdir -p "$HOME/Downloads" 2>/dev/null
mkdir -p "$DDIR" 2>/dev/null
mkdir -p "$WDIR" 2>/dev/null

cp ./* "$WDIR/"

touch "$DDIR/First Run"
echo "" > "$PIDF"
echo "" > "$LOCK"

cd "$WDIR"
"$CHROME" $ARGS \
  --enable-widevine --user-data-dir=$DDIR --silent-launch \
  --load-and-launch-app=`pwd` "$PIDF" 2>/dev/null

sleep 1
cleanup
