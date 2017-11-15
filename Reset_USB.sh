#!/bin/bash
pcpwd=123456
set -euo pipefail
IFS=$'\n\t'

VENDOR=$1
PRODUCT=$2
WAITTIME=$3

for DIR in $(find /sys/bus/usb/devices/ -maxdepth 1 -type l); do
  if [[ -f $DIR/idVendor && -f $DIR/idProduct &&
        $(cat $DIR/idVendor) == $VENDOR && $(cat $DIR/idProduct) == $PRODUCT ]]; then
    echo "DIR : $DIR"
    echo $pcpwd | sudo -S sh -c "echo 0 > $DIR/authorized"
    sleep 0.5
    
  fi
done
adb devices
sleep $WAITTIME

for DIR in $(find /sys/bus/usb/devices/ -maxdepth 1 -type l); do
  if [[ -f $DIR/idVendor && -f $DIR/idProduct &&
        $(cat $DIR/idVendor) == $VENDOR && $(cat $DIR/idProduct) == $PRODUCT ]]; then
    echo "DIR : $DIR"
    echo $pcpwd | sudo -S sh -c "echo 1 > $DIR/authorized"
    sleep 0.5

  fi
done
sleep 1
adb devices
exit 0
