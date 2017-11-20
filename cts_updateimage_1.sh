#!/bin/bash

echo
echo =======start ==========
date
echo

#sudo ./fastboot_8953 devices | awk '{print $1}' >SN

sleep 1

for dutsn in $(cat ./SN)
do
  ./update_image.sh $dutsn  &
  sleep 3
done
wait





