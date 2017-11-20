#!/bin/bash 

IMGPATH=$1
CTS_VERSION=$2
TESTPLAN=$3
HOME_PATH=~/Desktop/Image
ANDROID_VERSION=$(echo $CTS_VERSION | awk -F[r] '{print $1}')
PROJECT=$(echo $IMGPATH | awk -F[/] '{print $3}' | awk  -F[_] '{print $1}')
SKU=$(echo $IMGPATH | awk -F[/] '{print $6}' | awk  -F[-] '{print $1}')
BRANCH=$(echo $IMGPATH | awk -F[/] '{print $4}')
IMAGE=$(echo $IMGPATH | awk -F[/] '{print $5}')

pcPassword=123
WIFINAME=ASUS_Test
WIFIPASSWORD=20130802

TIMEOUT1=90
TIMEOUT2=60
TIMEOUT3=30
SKIPCOPYMEDIAFILE=0
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

echo ${pcPassword} | sudo -S rm -rf *_$PROJECT
echo ${pcPassword} | sudo -S rm -rf SN
echo ${pcPassword} | sudo -S rm -rf info_$PROJECT.txt
echo ${pcPassword} | sudo -S rm -rf DUTSN_$PROJECT
echo ${pcPassword} | sudo -S rm -rf DUTINFO_$PROJECT
echo ${pcPassword} | sudo -S rm -rf cts-report_$PROJECT
echo ${pcPassword} | sudo -S rm -rf cts-report_$PROJECT.zip

sleep 1

echo
echo " ===== find request devices ===== "

adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN

for DUTSN in $(cat $HOME_PATH/SN)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "aquarius" ]] && [[ $Variant == "ASUS_Z01F_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    else
        sleep 1
    fi  
done



DUT=$(awk '{print $1}' DUTSN_$PROJECT) 
if [[ $DUT == "" ]] ; then
       echo ================================
       echo " ===== No available device find,exit ===== "
       echo ================================ 
       exit 1
fi

echo ${pcPassword} | sudo -S chmod 777 ftp.sh

./ftp.sh $IMGPATH $TIMEOUT1 $TIMEOUT2 $TIMEOUT3
if [ $? -ne 0 ] ; then
   echo " ===== fail run ftp.sh,exit ===== "
   exit 1
fi
IMAGEFILE=$(awk '{print $9}' tmp3_$PROJECT)

sleep 1

echo ${pcPassword} | sudo -S chmod a+x Run.sh
echo ${pcPassword} | sudo -S chmod a+x cts_updateimage_Hades_N.sh
echo ${pcPassword} | sudo -S chmod a+x update_image_Hades_N.sh
echo ${pcPassword} | sudo -S chmod a+x info.sh

./Run.sh $IMAGEFILE $WIFINAME $WIFIPASSWORD $PROJECT $SKIPCOPYMEDIAFILE $SKU $ANDROID_VERSION $CTS_TOOL_VERSION $TESTPLAN

if [ $? -ne 0 ] ; then
   echo "fail run run.sh,exit"
   exit 1
fi

echo 
date
echo "send notify mail"
echo
echo ${pcPassword} | sudo -S rm -rf $HOME_PATH/cts-report_$PROJECT.zip
sleep 1
echo ${pcPassword} | sudo -S zip -r $HOME_PATH/cts-report_$PROJECT.zip $HOME_PATH/cts-report_$PROJECT
echo ${pcPassword} | sudo -S sudo chmod 777 $HOME_PATH/cts-report_$PROJECT.zip
sleep 1
 
echo "$IMAGEFILE CTS report check" | mail -s "$IMAGEFILE cts report please check " -a $HOME_PATH/cts-report_$PROJECT.zip  $MAILGROUP

echo 
date
echo "send notify mail done"
echo


exit 0

