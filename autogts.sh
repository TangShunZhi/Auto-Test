#!/bin/bash

PROJECT=$1
IMAGE=$2
SKU=$3
BRANCH=$4
serialnumber=$5

pcPassword=123
WIFINAME=ASUS_vpn3
WIFIPASSWORD=20130802

TIMEOUT1=600
TIMEOUT2=120
TIMEOUT3=120
SKIPCOPYMEDIAFILE=1
DEBUG=0


if [[ $DEBUG == 1 ]]; then
        MAILGROUP="pausebreak_cheng@asus.com"
else
    if [[ $PROJECT == "phoenix" ]] ;then
        MAILGROUP="pausebreak_cheng@asus.com,alvin_tang@asus.com"
    elif [[ $PROJECT == "hades" ]] ;then
        MAILGROUP="pausebreak_cheng@asus.com,alvin_tang@asus.com"
    elif [[ $PROJECT == "scorpio" ]] ;then
        MAILGROUP="pausebreak_cheng@asus.com,alvin_tang@asus.com"
    else
        MAILGROUP="pausebreak_cheng@asus.com"
    fi

fi


date

echo ${pcPassword} | sudo -S rm -rf tmp_$PROJECT
echo ${pcPassword} | sudo -S rm -rf tmp2_$PROJECT
echo ${pcPassword} | sudo -S rm -rf tmp3_$PROJECT
echo ${pcPassword} | sudo -S rm -rf tmp4_$PROJECT
echo ${pcPassword} | sudo -S rm -rf SN
echo ${pcPassword} | sudo -S rm -rf info_$PROJECT.txt
echo ${pcPassword} | sudo -S rm -rf DUTSN_$PROJECT
echo ${pcPassword} | sudo -S rm -rf DUTINFO_$PROJECT
echo ${pcPassword} | sudo -S rm -rf gts-report_$PROJECT
echo ${pcPassword} | sudo -S rm -rf gts-report_$PROJECT.zip

sleep 1

echo
echo "find request devices"

adb devices | awk '$2~/device/{print $1}' > SN

for DUTSN in $(cat ./SN)
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
echo ${pcPassword} | sudo -S chmod 777 DUTSN_$PROJECT
done



DUT=$(awk '{print $1}' DUTSN_$PROJECT) 
if [[ $DUT == "" ]] ; then
       echo ================================
       echo "No available device find,exit "
       echo ================================ 
       exit 1
fi

echo ${pcPassword} | sudo -S chmod a+x ftp.sh

./ftp.sh $PROJECT $IMAGE $SKU $BRANCH $TIMEOUT1 $TIMEOUT2 $TIMEOUT3
sleep 3
if [ $? -ne 0 ] ; then
   echo "fail run ftp.sh,exit"
   exit 1
fi
IMAGEFILE=$(awk '{print $9}' tmp3_$PROJECT)

#IMAGEFILE=WW-ZD552KL-3.1.134.16-CTS-user-20170525151857-release.zip
#IMAGEFILE=WW-msm8937-30.40.13.8-MR0-user-20170526-release.zip

sleep 1

echo ${pcPassword} | sudo -S chmod a+x rung.sh
echo ${pcPassword} | sudo -S chmod a+x cts_updateimage_Hades_N.sh
echo ${pcPassword} | sudo -S chmod a+x update_image_Hades_N.sh
echo ${pcPassword} | sudo -S chmod a+x info.sh

./rung.sh $IMAGEFILE $WIFINAME $WIFIPASSWORD $PROJECT $SKIPCOPYMEDIAFILE $DEBUG $SKU $serialnumber

if [ $? -ne 0 ] ; then
   echo "fail run rung.sh,exit"
   exit 1
fi

echo 
date
echo "send notify mail"
echo
echo ${pcPassword} | sudo -S rm -rf gts-report_$PROJECT.zip
sleep 1
echo ${pcPassword} | sudo -S zip -r gts-report_$PROJECT.zip gts-report_$PROJECT
echo ${pcPassword} | sudo -S sudo chmod 777 gts-report_$PROJECT.zip
sleep 1
 
echo "$IMAGEFILE GTS report check" | mail -s "$IMAGEFILE gts report please check " -a gts-report_$PROJECT.zip  $MAILGROUP

echo 
date
echo "send notify mail done"
echo




