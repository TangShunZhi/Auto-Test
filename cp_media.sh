#!/bin/bash


MEDIAFILE_PATH=~/Desktop/android-cts/android-cts-media-1.2
HOME_PATH=~/Desktop/Image

sudo rm -rf SN
sleep 1

echo
echo =======wait for devices=========
echo

#adb devices | sed '1d' |  awk '{print $1}' >SN 

adb devices | awk '$2~/device/{print $1}' > SN

sleep 1

for DUTSN in $(cat SN)
do
	adb -s $DUTSN wait-for-device 
	sleep 1
done


echo
echo =======copy mdeia file==========
echo

cd $MEDIAFILE_PATH


for DUTSN in $(cat $HOME_PATH/SN)
do
	. $MEDIAFILE_PATH/copy_media.sh 1920x1080 -s $DUTSN 
	sleep 3
done




