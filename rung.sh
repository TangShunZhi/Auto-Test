#!/bin/bash

pcPassword=123
IMAGE_NAME=$1
WIFINAME=$2
WIFIPASSWORD=$3
PROJECT=$4
SKIPCOPYMEDIAFILE=$5
DEBUG=$6
SKU=$7
serialnumber=$8
ANDROID_VERSION=71

MEDIAFILE_PATH=~/CTS/android-cts-media-1.2

HOME_PATH=~/Desktop/Image

#if [ $ANDROID_VERSION == 6 ];then
#	CTS_PATH=~/Desktop/android-cts/6.0r16/android-cts/tools
#	CtsDeviceAdmin_PATH=~/Desktop/android-cts/6.0r16/
#elif [ $ANDROID_VERSION == 7 ];then
#	CTS_PATH=~/Desktop/android-cts/7.0r7/android-cts/tools
#
#elif [ $ANDROID_VERSION == 71 ];then
GTS_PATH=~~/android-gts/4.1-r2/android-gts/tools

#else
#	echo
#	echo =======FIND ANDROID_VERSION ERROR==========
#	echo	
#	exit 1
#fi

echo
echo =======unzip image==========
date
echo

sudo unzip -o $IMAGE_NAME

if [ $ANDROID_VERSION == 6 ];then

	sudo cp update_image1.sh update_image.sh
	sudo cp cts_updateimage_1.sh cts_updateimage.sh

else

    if [[ $PROJECT == "scorpio" ]]; then
        sudo cp update_image_Scorpio_N71.sh update_image.sh
	sudo chmod a+x update_image.sh
	sudo chmod a+x cts_updateimage.sh
	sudo chmod a+x fastboot_8937
    else
	sudo cp update_image_Hades_N.sh update_image.sh
	sudo cp cts_updateimage_Hades_N.sh cts_updateimage.sh
	sudo chmod a+x update_image.sh
	sudo chmod a+x cts_updateimage.sh
	sudo chmod a+x fastboot_8953
    fi  


fi



echo
echo =======update image=========
date
echo


sleep 1

	adb -s $serialnumber wait-for-device 
	sleep 1
	adb -s $serialnumber reboot bootloader 
	sleep 1

sleep 5

if [[ $PROJECT == "scorpio" ]]; then
    sudo ./cts_updateimage.sh 123456
else
    sudo ./update_image.sh $serialnumber
	wait
fi


echo
echo =======wait for devices reboot 240 seconds=========
date
echo
sleep 240

echo =====================================
echo "adb devices again"
echo | adb devices | awk '$2~/offline/{print $0}'
echo =====================================

adb devices | awk '$2~/device/{print $1}' > SN

rm -rf $HOME_PATH/DUTSN_$PROJECT

for DUTSN in $(cat $HOME_PATH/SN)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN >>DUTSN_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN >>DUTSN_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN >>DUTSN_$PROJECT
    else
        sleep 1
    fi  
done


DUT1=$(awk '{print $1}' DUTSN_$PROJECT) 
if [[ $DUT1 == "" ]] ; then
       echo ================================
       echo "No available device find,exit "
       echo ================================ 
       exit 1
fi

sleep 10

for DUTSN in $(cat ./DUTSN_$PROJECT)
do
       echo ================================
       echo "wait for device $DUTSN"
       echo ================================
       adb -s $serialnumber wait-for-device 
       sleep 3
done

echo
echo =======do some settings before run gts==========
echo
sleep 3

	echo "=======DUT Is $serialnumber========="
	#echo =======press power key event==========
	#adb -s $DUTSN shell input keyevent 26
	#sleep 1
#	echo =======1.skip setup wizard==========
#	adb -s $DUTSN shell settings put global device_provisioned 1
#	sleep 1
#	adb -s $DUTSN shell settings put secure user_setup_complete 1
#	sleep 1
#	adb -s $DUTSN shell monkey -p com.asus.launcher -v 1
#	sleep 1
	echo =======1.screen off timeout==========
	adb -s $serialnumber shell settings put system screen_off_timeout 600000
	sleep 1
	echo =======2.stay awake==========
	adb -s $serialnumber shell settings put global stay_on_while_plugged_in 1
	sleep 1		
	echo =======3.disable package verifier enable=====
        adb -s $serialnumber shell settings put global package_verifier_enable 0
	sleep 1	



echo =======collect info ==========
sudo ./info.sh $PROJECT
echo =======collect done ==========

if [[ $SKIPCOPYMEDIAFILE -eq 1 ]]; then

    echo
    echo =======skip copy mdeia file==========
    echo

else

    echo
    echo =======copy mdeia file==========
    echo
    date
    cd $MEDIAFILE_PATH
    for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
    do
	. $MEDIAFILE_PATH/copy_media.sh 1920x1080 -s $DUTSN &
	sleep 3
    done
    wait
#    sleep 1200

    echo
    echo =======copy mdeia file done==========
    echo
    date

fi


if [ $ANDROID_VERSION == 6 ];then

	echo
	echo =======install CtsDeviceAdmin ==========
	echo
	cd $CtsDeviceAdmin_PATH
	for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
	do
		adb -s $DUTSN install -r android-cts/repository/testcases/CtsDeviceAdmin.apk
		sleep 3
	done
	
fi



cd $HOME_PATH


echo
echo =======do some pretest step 2 =========
echo
sleep 3
    echo =======Check SIM=========
    sim1=$(echo | adb -s $serialnumber shell getprop gsm.sim1.present)
    sim2=$(echo | adb -s $serialnumber shell getprop gsm.sim2.present)
    if [ $sim1 -eq 1 ] || [ $sim2 -eq 1 ] ; then
       DUTSIM=yes
       echo =======YES SIM==========
   else
       DUTSIM=no
       echo =======No SIM =========
   fi


	adb -s $serialnumber push $HOME_PATH/apk_phoenix/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard
    sleep 5
	adb -s $serialnumber shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"
    sleep 5
	adb -s $serialnumber push $HOME_PATH/apk_phoenix/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test
    sleep 5
	adb -s $serialnumber shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"
    sleep 5
        adb -s $serialnumber shell am instrument -w -r -e project $PROJECT -e sku $SKU -e sim $DUTSIM -e debug false -e class com.tdc.cts.skipsetupwizard.ExampleInstrumentedTest  com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner
    sleep 5

    echo =======before run cts ,setup wifi ==========
   
    echo | $GTS_PATH/gts-tradefed run util/wifi --wifi-network $WIFINAME --wifi-psk $WIFIPASSWORD --no-disconnect-wifi-after-test -s $serialnumber
    sleep 1
	wait
	adb -s $DUTSN shell pm uninstall com.tdc.cts.skipsetupwizard
	sleep 3
	adb -s $DUTSN shell pm uninstall com.tdc.cts.skipsetupwizard.test
	sleep 3
done




echo
echo =======run gts ==========
echo
date
echo

echo ${pcPassword} | sudo -S cp rungts.sh $GTS_PATH/rungts.sh


echo ${pcPassword} | sudo -S chmod 777 $GTS_PATH/rungts.sh 


Num=`sed -n '$=' DUTSN_$PROJECT`

cd $GTS_PATH


echo === using $serialnumber run gts ===
sleep 1


./rungts.sh $PROJECT $DEBUG $SKU $IMAGE_NAME $serialnumber

#./cts-tradefed run cts --plan CTS --abi arm64-v8a --shards $Num

#./cts-tradefed run cts --plan CTS --skip-preconditions --force-abi 64 --shards $Num

#./cts-tradefed run cts --product-type qcom:ASUS_Z01H_1 --plan CTS --abi arm64-v8a --shards $Num






