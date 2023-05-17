#!/bin/bash

function cleanup {
  rm "$LOCK" 2>/dev/null
  exit 0
}

XWMC=`defaults read WebBrowser xembedded_last_wmclass 2>/dev/null`
read -r a b c <<<"$XWMC"
if [ -n "$c" ];then
  wdwrite WMWindowAttributes "$c.*" '{ NoAppIcon = Yes; Unfocusable = Yes; }'
fi

trap cleanup SIGINT SIGTERM

CHROME=`type -p google-chrome`
[ -z "$CHROME" ] && CHROME=`type -p chromium`
[ -z "$CHROME" ] && CHROME=`type -p chromium-browser`
[ -z "$CHROME" ] && CHROME=`type -p chrome`

if [ -z "$CHROME" ];then
  echo "no google-chrome|chromium|chromium-browser|chrome found!"
  exit 10
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
"$CHROME" --enable-widevine --user-data-dir=$DDIR --silent-launch --load-and-launch-app=`pwd` "$PIDF"

sleep 1
cleanup
