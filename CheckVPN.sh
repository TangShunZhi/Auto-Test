#!/bin/bash
HOME_PATH=~/Desktop/Image
PROJECT=$1


cd $HOME_PATH

adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN

for DUTSN in $(cat $HOME_PATH/SN)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN > $HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN > $HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN > $HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "aquarius" ]] && [[ $Variant == "ASUS_Z01F_1" ]];then
        echo $DUTSN > $HOME_PATH/DUTSN_$PROJECT
    else
        sleep 1
    fi  
done


time=1
while [ $time -lt 99 ]
do

	for DUTSN in $(cat DUTSN_$PROJECT)
	do
	adb -s $DUTSN install supervpn.apk
	sleep 3
	adb -s $DUTSN shell am start -n com.jrzheng.supervpnfree/com.jrzheng.supervpn.view.MainActivity
	sleep 3
	adb -s $DUTSN shell input tap 70 90
	sleep 20
	adb -s $DUTSN shell input tap 550 780
	sleep 60
	input tap 880 1350
	sleep 20
	adb -s $DUTSN shell input keyevent 3
	done

sleep 29m

	for DUTSN in $(cat DUTSN_$PROJECT)
	do
	sleep 3
	adb -s $DUTSN shell am force-stop com.jrzheng.supervpnfree
	done

time=$(($time+1))
done

exit 0
