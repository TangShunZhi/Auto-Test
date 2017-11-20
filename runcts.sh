#!/bin/bash
export cnt=10
export usedsession=0
export pcPassword=123456
HOME_PATH=~/Desktop/Image
PROJECT=$1
DEBUG=$2
IMAGE_NAME=$3
CTSPATH=$4
#export CTSPATH=~/android-cts/7.1r6/android-cts
export CTStool=$CTSPATH/tools
export CTSresult=$CTSPATH/results/
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
echo ${pcPassword} | sudo -S mkdir $CTSPATH/TestHistory/
echo ${pcPassword} | sudo -S chmod 777 -R $CTSPATH/TestHistory/
echo ${pcPassword} | sudo -S mkdir $CTSPATH/TestHistory/TestHistory.txt
echo ${pcPassword} | sudo -S chmod 777 $CTSPATH/TestHistory/TestHistory.txt
echo ${pcPassword} | sudo -S mkdir $HOME_PATH/cts-report_$PROJECT/
echo ${pcPassword} | sudo -S chmod 777 -R $HOME_PATH/cts-report_$PROJECT/

GetPhoneNumber(){
	phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}')
        echo "GetPhoneNumber"
	#phonenumber=$(awk 'BEGIN{i=0}{++i}END{print i}' $HOME_PATH/DUTSN_$PROJECT)
        #echo "phonenumber is $phonenumber"
}

GetResult(){
        #echo "GetResult"
        #count=1	
	echo | $CTStool/cts-tradefed l r | awk '/of/{print}' > result.txt	
	ResultNumber=$(echo | cat -n result.txt | awk 'END{print $1}')
        SessionID=$(echo | cat result.txt | awk 'END{print $1}')
	resultpath=$(echo | cat result.txt | awk 'END{print $7}')
        echo SessionID is $SessionID
	echo Resultpat is $resultpath
	#while [ $count -eq 1 ]
	#do
 	#    LastTypeReport=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $0}}') 
        #    echo  LastTypeReport is $LastTypeReport
	#    #Name=$(awk 'END{print $2}' $HOME_PATH/DUTINFO_$PROJECT)
	#    Name=$(awk 'END{print $1}' $HOME_PATH/DUTINFO_$PROJECT)
        #    Match=$(echo $LastTypeReport | awk '$0~/'$Name'/{print $0}')
        #    if [[ $Match == "" ]]; then
        #      SessionID=$[ $SessionID -1 ]
	#    else
	#      echo Match is $Match
	#      count=0
	#    fi
	#done
}

GetSim(){
        #echo "GetSim"
        phonesn=$(echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}')
	#phonesn=$(echo | awk '{print $1}' $HOME_PATH/DUTINFO_$PROJECT )
#	echo $phonesn
	for var in $phonesn; do
#		echo $var
   		sim1=$(echo | adb -s $var shell getprop gsm.sim1.present)
		if [ $sim1 -eq 1 ]; then
			simsn="--device-token $var:sim-card"
			serialnumber=$var
		fi
                sim2=$(echo | adb -s $var shell getprop gsm.sim2.present)
                if [ $sim2 -eq 1 ]; then
                        simsn="--device-token $var:sim-card"
			serialnumber=$var
                fi
	done
}

echo
echo =======collect dut product-type==========

adb devices | awk '$2~/device/{print $1}' > $HOME_PATH/SN

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
done

touch $HOME_PATH/DUTINFO_$PROJECT

for DUTSN in $(cat $HOME_PATH/DUTSN_$PROJECT)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    Name=$(adb -s $DUTSN shell "getprop ro.product.name")
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN $Name $Variant qcom:$Variant >>$HOME_PATH/DUTINFO_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN $Name $Variant qcom:$Variant >>$HOME_PATH/DUTINFO_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN $Name $Variant qcom:$Variant >>$HOME_PATH/DUTINFO_$PROJECT
    
    else
        sleep 1
    fi  
done

GetPhoneNumber
if [ $phonenumber -eq 0 ]; then
echo can not find any device,so exit!!
exit 10
fi	

simsn=
GetSim
echo $simsn

echo use shards $phonenumber!!!!
echo will retry $cnt count!!!!!


DUTTYPE=$(awk 'BEGIN{} {} END{print $4}' $HOME_PATH/DUTINFO_$PROJECT)
if [ "$2" == "retry" ]; then
	echo will retry
else

	if [[ $DEBUG == 1 ]]; then
        	echo | $CTStool/cts-tradefed run cts -m CtsAbiOverrideHostTestCases --product-type $DUTTYPE $simsn -a arm64-v8a -o
        else
		echo | $CTStool/cts-tradefed run cts -o --shards $phonenumber  $simsn 
        fi

fi

while(($cnt>0))

do
GetPhoneNumber
if [ $phonenumber -eq 0 ]; then
echo can not find any device,so exit!!
exit 10
fi	

simsn=
GetSim
echo $simsn

if [ "$2" == "retry" ]; then
	if [ "$usedsession" == "0" ]; then
	if [ -n "$3" ]; then
		SessionID=$3
		usedsession=1
	fi
	fi
fi	
	GetResult
	echo $resultpath
	awk -f ctsn.awk $CTSresult/$resultpath/test_result.xml   >$CTSresult/$resultpath/test_result_new.xml
	mv $CTSresult/$resultpath/test_result_new.xml  $CTSresult/$resultpath/test_result.xml
        result1pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result1fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result1notexcute=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
	echo now we will retry $cnt times; 
	echo retry session $SessionID
	GetResult
        if [[ $DEBUG == 1 ]]; then
	     echo | $CTStool/cts-tradefed run cts --product-type $DUTTYPE -r $SessionID $simsn -a arm64-v8a -o
        else
             echo | $CTStool/cts-tradefed run cts -r $SessionID -o --shards $phonenumber  $simsn 
        fi

	GetResult
        result2pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result2fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result2notexcute=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
        echo $result1pass $result1fail $result1notexcute 
	echo $result2pass $result2fail $result2notexcute 
	echo SessionID=$SessionID
	#if [ $result2notexcute -eq 0 ]; then
		if [ $result1pass -eq $result2pass ]; then	
				if [ $result1fail -eq $result2fail ]; then	
					GetResult
					echo | $CTStool/cts-tradefed run cts -r $SessionID --serial $serialnumber
sleep 60
					GetResult
					echo | $CTStool/TestHistory.sh $IMAGE_NAME $CTSPATH
					echo ${pcPassword} | sudo -S cp $CTSresult/$resultpath/test_result_failures.html $HOME_PATH/cts-report_$PROJECT/test_result_failures.html
                                        echo ${pcPassword} | sudo -S cp $CTSresult/$resultpath.zip $HOME_PATH/cts-report_$PROJECT/$resultpath.zip
					#echo ${pcPassword} | sudo -S zip -r $HOME_PATH/cts-report_$PROJECT/log_$resultpath.zip $CTSPATH/logs/$resultpath 
					echo ${pcPassword} | sudo -S mv $CTSresult/* $CTSPATH/TestHistory/
					echo done  --------------------------------------------------done
					exit 0
				fi	
		fi	
	#fi
	cnt=$[cnt-1]
done
echo "retry count is full"
GetResult
echo | $CTStool/cts-tradefed run cts -r $SessionID --serial $serialnumber
sleep 60 
GetResult
echo | $CTStool/TestHistory.sh $IMAGE_NAME $CTSPATH
echo ${pcPassword} | sudo -S cp $CTSresult/$resultpath/test_result_failures.html $HOME_PATH/cts-report_$PROJECT/test_result_failures.html
echo ${pcPassword} | sudo -S cp $CTSresult/$resultpath.zip $HOME_PATH/cts-report_$PROJECT/$resultpath.zip
#echo ${pcPassword} | sudo -S zip -r $HOME_PATH/cts-report_$PROJECT/log_$resultpath.zip $CTSPATH/logs/$resultpath 
echo ${pcPassword} | sudo -S mv $CTSresult/* $CTSPATH/TestHistory/
echo done  --------------------------------------------------done
exit 0
