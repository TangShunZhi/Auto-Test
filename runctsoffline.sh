#!/bin/bash
CTSPATH=$1
TESTPLAN=$2
PROJECT=$3
pcPassword=123
export CTStool=$CTSPATH/tools
export CTSresult=$CTSPATH/results
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
export cnt=25
export usedsession=0
if [[ $TESTPLAN -eq 1 ]] || [[ $TESTPLAN -eq 2 ]];then
export limit=140
else
export limit=280
fi

echo $pcPassword | sudo -S touch $HOME_PATH/SN
echo $pcPassword | sudo -S chmod 777 $HOME_PATH/SN
adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN
echo ${pcPassword} | sudo -S chmod 777 $HOME_PATH/DUTSN_$PROJECT
echo ${pcPassword} | sudo -S cat /dev/null > $HOME_PATH/DUTSN_$PROJECT

for DUTSN in $(cat $HOME_PATH/SN)
do
    if [[ $DUTSN == "GBAZCY03V721NNM" ]];then
	echo "GBAZCY03V721NNM is for GTS"
	export gts=1
    else
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
    fi  
done

cd $CTSPATH
echo ${pcPassword} | sudo -S rm CTSSN
for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
	echo -e " --serial $DUTSN \c" >> CTSSN 
done
CTSSN=$(cat $CTSPATH/CTSSN)

GetPhoneNumber(){
	#phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}')
	phonenumber=$(awk 'BEGIN {t=0;}{t++;}END{print t;}' $HOME_PATH/DUTSN_$PROJECT)
}

GetResult(){	
	echo | $CTStool/cts-tradefed l r | awk '/of/{print}' > $CTStool/result.txt	
	ResultNumber=$(echo | cat -n $CTStool/result.txt | awk 'END{print $1}')
        SessionID=$(echo | cat $CTStool/result.txt | awk 'END{print $1}')
	resultpath=$(echo | cat $CTStool/result.txt | awk 'END{print $7}')
        echo SessionID is $SessionID
	echo Resultpat is $resultpath
}

GetSim(){
        phonesn=$(echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}')
	for var in $phonesn; do
   		sim1=$(echo | adb -s $var shell getprop gsm.sim1.present)
		if [[ $sim1 -eq 1 ]]; then
			simsn="--device-token $var:sim-card"
			serialnumber=$var
		fi
                sim2=$(echo | adb -s $var shell getprop gsm.sim2.present)
                if [[ $sim2 -eq 1 ]]; then
                        simsn="--device-token $var:sim-card"
			serialnumber=$var
                fi
	done
}



GetPhoneNumber
if [[ $phonenumber -eq 0 ]]; then
echo can not find any device,so exit!!
exit 10
fi	

simsn=
GetSim
echo $simsn

echo use shards $phonenumber!!!!
echo will retry $cnt count!!!!!

if [[ "$2" == "retry" ]]; then
	echo will retry
else
	if [[ $TESTPLAN -eq 1 ]];then
	bash $CTStool/cts-tradefed run cts -o -d -a arm64-v8a $CTSSN --shards $phonenumber $simsn
	else
	if [[ $TESTPLAN -eq 2 ]];then
	bash $CTStool/cts-tradefed run cts -o -d -a armeabi-v7a $CTSSN --shards $phonenumber $simsn
	else
	if [[ $TESTPLAN -eq 3 ]];then
	bash $CTStool/cts-tradefed run cts -o -d $CTSSN --shards $phonenumber $simsn
	else
	echo "ERROR TESTPLAN!!! Plese Choice 1,2or3"
	exit 1
	fi
	fi
	fi
fi

while(($cnt>0))

do
GetPhoneNumber
if [[ $phonenumber -eq 0 ]]; then
echo can not find any device,so exit!!
exit 10
fi	

simsn=
GetSim
echo $simsn

GetResult
if [[ "$2" == "retry" ]]; then
	if [[ "$usedsession" == "0" ]]; then
	if [[ -n "$3" ]]; then
		SessionID=$3
		usedsession=1
	fi
	fi
fi	
	awk -f ctsn.awk $CTSresult/$resultpath/test_result.xml   >$CTSresult/$resultpath/test_result_new.xml
	mv $CTSresult/$resultpath/test_result_new.xml  $CTSresult/$resultpath/test_result.xml
        result1pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result1fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result1done=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
	echo now we will retry $cnt times; 
	echo "retry session ID : $SessionID"
        bash $CTStool/cts-tradefed run cts -o -r $SessionID --shards $phonenumber $simsn $CTSSN
	GetResult
        result2pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result2fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result2done=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
        echo $result1pass $result1fail $result1done 
	echo $result2pass $result2fail $result2done 
	echo SessionID=$SessionID
	if [[ $result2done -ge $limit ]] ; then
		if [[ $result1pass -eq $result2pass ]]; then	
				if [[ $result1fail -eq $result2fail ]]; then	
GetResult
echo | adb -s $serialnumber install $CTStool/LiuChang.apk
sleep 15
bash $CTStool/cts-tradefed run util/wifi --wifi-network ASUS_Test --wifi-psk 20130801 --no-disconnect-wifi-after-test -s $serialnumber
wait
echo | adb -s $serialnumber push $CTStool/app-debug.apk /data/local/tmp/com.retrytest.retrytest
sleep 5
echo | adb -s $serialnumber shell pm install -r "/data/local/tmp/com.retrytest.retrytest"
sleep 5
echo | adb -s $serialnumber push $CTStool/app-debug-androidTest.apk /data/local/tmp/com.retrytest.retrytest.test
sleep 5
echo | adb -s $serialnumber shell pm install -r "/data/local/tmp/com.retrytest.retrytest.test"
sleep 5
echo | adb -s $serialnumber shell  am instrument  -w -r  -e debug false -e class com.retrytest.retrytest.ExampleInstrumentedTest com.retrytest.retrytest.test/android.support.test.runner.AndroidJUnitRunner
wait
bash $CTStool/cts-tradefed run cts -o -r $SessionID -s $serialnumber
wait 
echo | adb -s $serialnumber reboot
sleep 150
echo | adb -s $serialnumber wait-for-device
GetResult
bash $CTStool/cts-tradefed run cts -o -r $SessionID -s $serialnumber
echo done 
exit 0
				fi	
		fi	
	fi
	cnt=$[cnt-1]
done
GetResult
echo | adb -s $serialnumber install $CTStool/LiuChang.apk
sleep 15
bash $CTStool/cts-tradefed run util/wifi --wifi-network ASUS_Test --wifi-psk 20130801 --no-disconnect-wifi-after-test -s $serialnumber
wait
echo | adb -s $serialnumber push $CTStool/app-debug.apk /data/local/tmp/com.retrytest.retrytest
sleep 5
echo | adb -s $serialnumber shell pm install -r "/data/local/tmp/com.retrytest.retrytest"
sleep 5
echo | adb -s $serialnumber push $CTStool/app-debug-androidTest.apk /data/local/tmp/com.retrytest.retrytest.test
sleep 5
echo | adb -s $serialnumber shell pm install -r "/data/local/tmp/com.retrytest.retrytest.test"
sleep 5
echo | adb -s $serialnumber shell  am instrument  -w -r  -e debug false -e class com.retrytest.retrytest.ExampleInstrumentedTest com.retrytest.retrytest.test/android.support.test.runner.AndroidJUnitRunner
wait
bash $CTStool/cts-tradefed run cts -o -r $SessionID -s $serialnumber
wait 
echo | adb -s $serialnumber reboot
sleep 150
echo | adb -s $serialnumber wait-for-device
GetResult
bash $CTStool/cts-tradefed run cts -o -r $SessionID -s $serialnumber
echo done 
exit 0
