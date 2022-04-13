#!/bin/bash

PFILE="/tmp/$$.pid"
touch $PFILE
chromium --silent-launch --load-and-launch-app=`pwd` $PFILE
