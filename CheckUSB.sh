#!/bin/bash
pause() { 
	read -n 1 -p "$*" INP
	if [ $INP! = '' ];
	then echo -ne '\b \n' 
	fi
}
WAIT_TIME=3
echo "=================================================="
echo "=============== Check devices status ============="
echo 
echo | adb devices | grep off
sig1=$?
echo | adb devices | grep permissions
sig2=$?

if [[ $sig1 -eq 0 ]] || [[ $sig2 -eq 0 ]];then
	echo "====== Bellow device(s) is NOT_CONNECTED!!! ======"
	echo | adb devices | awk '$2~/off/{print $1}'
	echo | adb devices | awk '$3~/permissions/{print $1}'
	echo | adb devices | awk '$2~/off/{print $1}' > ./OFFLINE
	echo | adb devices | awk '$3~/permissions/{print $1}' >>./OFFLINE
	echo 
	echo "============= Auto Reconnect USB  ================"
	sleep 3
	for DUT in $(cat OFFLINE);do
	bash RESET_DUT.sh $DUT &
	done
	sleep 3
	echo "=============== Check devices status ============="
	echo 
	adb devices
	echo | adb devices | grep off
	sig3=$?
	echo | adb devices | grep permissions
	sig4=$?
	if [[ $sig3 -eq 0 ]] || [[ $sig4 -eq 0 ]];then
		echo "========== Please Check DUT Manually =============" > mail.txt
		echo | adb devices | awk '$2~/off/{print $1}' >> mail.txt
		echo | adb devices | awk '$3~/permissions/{print $1}' >> mail.txt
		echo "============== Wait for 6 minutes ================"
		sleep 120
		adb devices
		echo "============== Wait for 4 minutes ================"
		sleep 120
		adb devices
		echo "============== Wait for 2 minutes ================"
		sleep 120
		adb devices
		echo "======= offline device will be excluded !  ======="
	else
		echo "=========== Devices USB status are Ok ============"
	fi

else
	echo "=========== Devices USB status are Ok ============"
fi
exit 0
