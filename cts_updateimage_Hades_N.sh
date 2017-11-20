#!/bin/bash

PROJECT=$1

echo
echo =======start ==========
date
echo

#sudo ./fastboot_8953 devices | awk '{print $1}' >SN

sleep 1

for dutsn in $(cat ./DUTSN_$PROJECT)
do
  ./update_image_Hades_N.sh $dutsn  &
  sleep 1
done
wait







