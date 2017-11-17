#!/bin/bash
pcpwd=123
set -euo pipefail
IFS=$'\n\t'


DUTSN=$1
WAIT_TIME=$2
#VENDOR=$1
#PRODUCT=$2

for DIR in $(find /sys/bus/usb/devices/ -maxdepth 3 -type l); do
  if [[ -f $DIR/idVendor && -f $DIR/idProduct && -f $DIR/serial && $(cat $DIR/serial) == $DUTSN && $(cat $DIR/authorized) == 0 ]]; then
    echo " ===== Recoonect device : $DUTSN ===== "
    echo $pcpwd | sudo -S sh -c "echo 1 > $DIR/authorized"
    sleep 0.5

  fi
done

echo  " ===== 1.screen off timeout ===== "
adb -s $DUTSN shell settings put system screen_off_timeout 600000
echo " ===== 2.stay awake ===== "
adb -s $DUTSN shell settings put global stay_on_while_plugged_in 7
echo " ===== 3.disable package verifier enable ===== "
adb -s $DUTSN shell settings put global package_verifier_enable 0

for DIR in $(find /sys/bus/usb/devices/ -maxdepth 3 -type l); do
  if [[ -f $DIR/idVendor && -f $DIR/idProduct && -f $DIR/serial && $(cat $DIR/serial) == $DUTSN  ]]; then
    echo " ===== Discoonect device : $DUTSN ===== "
    echo $pcpwd | sudo -S sh -c "echo 0 > $DIR/authorized"
    sleep 0.5
    
  fi
done
adb devices
sleep $WAIT_TIME

for DIR in $(find /sys/bus/usb/devices/ -maxdepth 3 -type l); do
  if [[ -f $DIR/idVendor && -f $DIR/idProduct && -f $DIR/serial && $(cat $DIR/serial) == $DUTSN  ]]; then
    echo " ===== Recoonect device : $DUTSN ===== "
    echo $pcpwd | sudo -S sh -c "echo 1 > $DIR/authorized"
    sleep 0.5

  fi
done
sleep 1
adb devices
exit 0
