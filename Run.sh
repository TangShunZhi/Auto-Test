#!/bin/bash 

pcPassword=123
IMAGE_NAME=$1
WIFINAME=$2
WIFIPASSWORD=$3
PROJECT=$4
SKIPCOPYMEDIAFILE=$5
SKU=$6
ANDROID_VERSION=$7
CTS_TOOL_VERSION=$8
TESTPLAN=$9

MEDIAFILE_PATH=~/android-cts/android-cts-media-1.4
HOME_PATH=~/Desktop/Image
pause() { read -n 1 -p "$*"
INP
	if [ $INP! = '' ];
	then echo -ne '\b \n' 
	fi
}

if [ $ANDROID_VERSION == 6.0 ];then
	CTSPATH=~/android-cts/$CTS_TOOL_VERSION/android-cts
	CTStool=$CTSPATH/tools
	CtsDeviceAdmin_PATH=~/Desktop/android-cts/$CTS_TOOL_VERSION
elif [ $ANDROID_VERSION == 7.0 ];then
	CTSPATH=~/android-cts/$CTS_TOOL_VERSION/android-cts
	CTStool=$CTSPATH/tools
elif [ $ANDROID_VERSION == 7.1 ];then
	CTSPATH=~/android-cts/$CTS_TOOL_VERSION/android-cts
	CTStool=$CTSPATH/tools
else
	echo
	echo =======FIND ANDROID_VERSION ERROR==========
	echo	
	exit 1
fi

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

for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
	adb -s $DUTSN wait-for-device 
	sleep 1
	adb -s $DUTSN reboot bootloader 
	sleep 1
done

sleep 5

if [[ $PROJECT == "scorpio" ]]; then
    sudo ./cts_updateimage.sh 123456
else
    sudo ./cts_updateimage.sh $PROJECT #for 8953
fi


echo
echo =======wait for devices reboot 240 seconds=========
date
echo

sleep 240
echo "====================Check DUT is offline?======================="
pause

echo =====================================
echo "adb devices again,maybe devices offline"
echo | adb devices | awk '$2~/offline/{print $0}'
echo =====================================

adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN

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

for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
       echo ================================
       echo "wait for device $DUTSN"
       echo ================================
       adb -s $DUTSN wait-for-device 
       sleep 3
done

echo
echo =======Do some settings before run cts==========
echo
sleep 3
for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
	echo =======DUT Is $DUTSN=========
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
	adb -s $DUTSN shell settings put system screen_off_timeout 600000
	sleep 1
	echo =======2.stay awake==========
	adb -s $DUTSN shell settings put global stay_on_while_plugged_in 7
	sleep 1	
	echo =======3.disable package verifier enable=====
        adb -s $DUTSN shell settings put global package_verifier_enable 0
	sleep 1		
done



echo =======collect info ==========
sudo ./info.sh $PROJECT
echo =======collect done ==========

if [ $ANDROID_VERSION == 6.0 ];then

	echo
	echo =======install CtsDeviceAdmin ==========
	echo
	cd $CtsDeviceAdmin_PATH
	for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
	do
		adb -s $DUTSN install -r $CtsDeviceAdmin_PATH/android-cts/repository/testcases/CtsDeviceAdmin.apk
		sleep 3
	done
	
fi

echo =======Skip setup wizard and prepare DUT==========
if [ $TESTPLAN == MONKEY ];then
testpath=$HOME_PATH/Monkey-sh
echo ${pcPassword} | sudo -S cp  $HOME_PATH/DUTprepare.sh $testpath/DUTprepare.sh
echo ${pcPassword} | sudo -S chmod 777  $testpath/DUTprepare.sh
cd $testpath
./DUTprepare.sh $testpath $pcPassword $PROJECT $SKU 
wait

else

testpath=$HOME_PATH/apk_$PROJECT/
echo ${pcPassword} | sudo -S cp  $HOME_PATH/DUTprepare.sh $HOME_PATH/apk_$PROJECT/DUTprepare.sh
echo ${pcPassword} | sudo -S chmod 777 $HOME_PATH/apk_$PROJECT/DUTprepare.sh
cd $testpath
./DUTprepare.sh $testpath $pcPassword $PROJECT $SKU 

sleep 30

fi

if [ $TESTPLAN == FOV ];then
echo "Do CTS-V FOV prepare"
cd $HOME_PATH/fov
export device=GBAZCY0250263SF
echo "===========Install CTS-V==========="
adb -s $device install $HOME_PATH/fov/CtsVerifier.apk
wait
echo "===========Open CTS-V==========="
adb -s $device shell am start -n com.android.cts.verifier/.CtsVerifierActivity 
sleep 3
echo "===========Do CTS-V setup==========="
adb -s $device push $HOME_PATH/fov/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard
adb -s $device shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"
wait
adb -s $device push $HOME_PATH/fov/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test
adb -s $device shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"
wait
adb -s $device shell am instrument -w -r   -e debug false -e class com.tdc.cts.skipsetupwizard.ExampleInstrumentedTest com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner
wait
./FOV.sh $device 

else


cd $HOME_PATH


echo
echo =======do some pretest step 2 =========
echo
sleep 3
for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
    echo
    echo =======DUT Is $DUTSN=========
    echo

    echo =======Check SIM=========
    sim1=$(echo | adb -s $DUTSN shell getprop gsm.sim1.present)
    sim2=$(echo | adb -s $DUTSN shell getprop gsm.sim2.present)
    if [ $sim1 -eq 1 ] || [ $sim2 -eq 1 ] ; then
       DUTSIM=yes
       echo =======YES SIM==========
   else
       DUTSIM=no
       echo =======No SIM =========
   fi


#	adb -s $DUTSN push $HOME_PATH/apk_$PROJECT/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"
#    sleep 5
#	adb -s $DUTSN push $HOME_PATH/apk_$PROJECT/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"
#    sleep 5
#        adb -s $DUTSN shell am instrument -w -r -e project $PROJECT -e sku $SKU -e sim $DUTSIM -e debug false -e class com.tdc.cts.skipsetupwizard.ExampleInstrumentedTest  com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner
#   sleep 5
#

#    echo =======Check SIM=========
#    sim1=$(echo | adb -s $DUTSN shell getprop gsm.sim1.present)
#    sim2=$(echo | adb -s $DUTSN shell getprop gsm.sim2.present)
#    if [ $sim1 -eq 1 ] || [ $sim2 -eq 1 ] ; then
#        echo =======YES SIM==========
#	adb -s $DUTSN push $HOME_PATH/apkSIM/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizardwithsim
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizardwithsim"
#    sleep 5
#	adb -s $DUTSN push $HOME_PATH/apkSIM/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizardwithsim.test
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizardwithsim.test"
#    sleep 5
#        adb -s $DUTSN shell am instrument -w -r  -e package com.tdc.cts.skipsetupwizardwithsim -e debug false com.tdc.cts.skipsetupwizardwithsim.test/android.support.test.runner.AndroidJUnitRunner
#    sleep 5
#    else
#        echo =======No SIM =========
#	adb -s $DUTSN push $HOME_PATH/apk/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"
#    sleep 5
#	adb -s $DUTSN push $HOME_PATH/apk/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test
#    sleep 5
#	adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"
#    sleep 5
#        adb -s $DUTSN shell am instrument -w -r  -e package com.tdc.cts.skipsetupwizard -e debug false com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner
#    sleep 5
#        adb -s $DUTSN shell svc data enable
#    sleep 5
#    fi

    echo =======before run cts ,setup wifi ==========
    #echo | $CTStool/cts-tradefed run util/wifi --wifi-network $WIFINAME --wifi-psk $WIFIPASSWORD --no-disconnect-wifi-after-test -s $DUTSN
    #sleep 1
    echo | $CTStool/cts-tradefed run util/wifi --wifi-network $WIFINAME --wifi-psk $WIFIPASSWORD --no-disconnect-wifi-after-test -s $DUTSN
    wait
	adb -s $DUTSN shell pm uninstall com.tdc.cts.skipsetupwizard
	sleep 3
	adb -s $DUTSN shell pm uninstall com.tdc.cts.skipsetupwizard.test
	sleep 3
done

echo =======Please Cheak DUT preconditions is OK==========
pause

if [ $TESTPLAN == MONKEY ];then
testpath=$HOME_PATH/monkey/monkey1
cd $testpath
./run.sh
wait
exit 0
fi



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
	./media.sh
	wait
    echo
    echo =======copy mdeia file done==========
    echo
    date

#echo =======before run cts ,reboot devices ==========
#for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
#do
#adb -s $DUTSN reboot
#done
sleep 300
echo =======Find Available devices ==========
adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN
echo ${pcPassword} | sudo -S chmod 777 $HOME_PATH/SN
echo ${pcPassword} | sudo -S rm $HOME_PATH/DUTSN_$PROJECT
for DUTSN in $(cat $HOME_PATH/SN)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    else
        sleep 1
    fi  
done


fi
echo
echo =======Run CTS Now==========
echo
date
echo

echo ${pcPassword} | sudo -S cp $HOME_PATH/runctsoffline.sh $CTStool/runctsoffline.sh
echo ${pcPassword} | sudo -S cp $HOME_PATH/ctsn.awk  $CTStool/ctsn.awk
echo ${pcPassword} | sudo -S cp $HOME_PATH/TestHistory.sh $CTStool/TestHistory.sh
echo ${pcPassword} | sudo -S cp $HOME_PATH/LiuChang.apk $CTStool/LiuChang.apk
echo ${pcPassword} | sudo -S cp $HOME_PATH/retry/app-debug.apk $CTStool/app-debug.apk
echo ${pcPassword} | sudo -S cp $HOME_PATH/retry/app-debug-androidTest.apk $CTStool/app-debug-androidTest.apk
echo ${pcPassword} | sudo -S chmod 777 $CTStool/*

echo === $Num devices found ===
echo === using $Num devices run cts ===


cd $CTStool
sleep 10
./runctsoffline.sh $CTSPATH $TESTPLAN

wait
./TestHistory.sh $IMAGE_NAME $CTSPATH
#./cts-tradefed run cts --plan CTS --abi arm64-v8a --shards $Num

#./cts-tradefed run cts --plan CTS --skip-preconditions --force-abi 64 --shards $Num

#./cts-tradefed run cts --product-type qcom:ASUS_Z01H_1 --plan CTS --abi arm64-v8a --shards $Num



fi

exit 0
