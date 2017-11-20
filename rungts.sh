export GTSPATH=~/android-gts/4.1-r2/android-gts
export GTStool=$GTSPATH/tools
export GTSresult=$GTSPATH/results
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
export cnt=5
export usedsession=0
export HOME_PATH=~/Desktop/Image
export pcPassword=123
PROJECT=$1
DEBUG=$2
SKU=$3
IMAGE_NAME=$4
serialnumber=$5
GetPhoneNumber(){
	#phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}')
	phonenumber=$(awk 'BEGIN{i=0}{++i}END{print i}' $HOME_PATH/DUTSN_$PROJECT)
}

GetResult(){	
	#GtsResult=$(echo | $GTStool/gts-tradefed l r | awk 'BEGIN{i=0} {a[i++]=$0}END{print a[i-3]}')
	#SessionID=$(echo | echo $GtsResult | awk '{print $1}')
	echo | $GTStool/gts-tradefed l r | awk '/of/{print}' > result.txt	
	ResultNumber=$(echo | cat -n result.txt | awk 'END{print $1}')
        SessionID=$(echo | cat result.txt | awk 'END{print $1}')
	resultpath=$(echo | cat result.txt | awk 'END{print $7}')
}

GetSim(){
        phonesn=$(echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}')
#	echo $phonesn
	for var in $phonesn; do
#		echo $var
   		sim1=$(echo | adb -s $var shell getprop gsm.sim1.present)
		if [ $sim1 -eq 1 ]; then
			simsn="--device-token $var:sim-card"
		fi
                sim2=$(echo | adb -s $var shell getprop gsm.sim2.present)
                if [ $sim2 -eq 1 ]; then
                        simsn="--device-token $var:sim-card"
                fi
	done
}


for DUTSN in $(cat $HOME_PATH/SN)
do
    Variant=$(adb -s $DUTSN shell "getprop ro.product.device")
    echo $Variant
    if [[ $PROJECT == "phoenix" ]] && [[ $Variant == "ASUS_Z01M_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "hades" ]] && [[ $Variant == "ASUS_Z01H_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    elif [[ $PROJECT == "scorpio" ]] && [[ $Variant == "Z01B_1" ]];then
        echo $DUTSN >>$HOME_PATH/DUTSN_$PROJECT
    else
        sleep 1
    fi  
echo ${pcPassword} | sudo -S chmod 777 -R $HOME_PATH/DUTSN_$PROJECT
done

#export serialnumber=$(echo | cat /$HOME_PATH/DUTSN_$PROJECT | awk 'NR==1{print}')
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

if [ "$1" == "retry" ]; then
	echo will retry
else
	if [ $DEBUG -eq 1 ]; then
	echo | $GTStool/gts-tradefed run gts -o --shards $phonenumber --product-type qcom:$Variant -m GtsPermissionTestCases
	else
	#if [ $phonenumber -eq 1 ]; then
	echo | $GTStool/gts-tradefed run gts -o --serial $serialnumber  -a armeabi-v7a
	#else
	#echo | $GTStool/gts-tradefed run gts -o --shards $phonenumber --product-type qcom:$Variant -a armeabi-v7a
	#fi
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


	GetResult
if [ "$1" == "retry" ]; then
	if [ "$usedsession" == "0" ]; then
	if [ -n "$2" ]; then
		SessionID=$2
		usedsession=1
	fi
	fi
fi	
	
	echo $resultpath
	#awk -f ctsn.awk $GTSresult/$resultpath/test_result.xml   >$CTSresult/$resultpath/test_result_new.xml
	#mv $GTSresult/$resultpath/test_result_new.xml  $CTSresult/$resultpath/test_result.xml
        result1pass=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result1fail=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result1notexcute=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
	echo now we will retry $cnt times; 
	echo retry session $SessionID
        echo | $GTStool/gts-tradefed run gts -o -r $SessionID --serial $serialnumber
	GetResult
        result2pass=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result2fail=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result2notexcute=$(echo | $GTStool/gts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
        echo $result1pass $result1fail $result1notexcute 
	echo $result2pass $result2fail $result2notexcute 
	echo SessionID=$SessionID
	#if [ $result2notexcute -eq 32 ]; then
		if [ $result1pass -eq $result2pass ]; then	
				if [ $result1fail -eq $result2fail ]; then
				GetResult
				resultpath=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $7}}')
				echo ${pcPassword} | sudo -S mkdir $HOME_PATH/gts-report_$PROJECT
				echo ${pcPassword} | sudo -S cp $GTSresult/$resultpath/test_result.xml $HOME_PATH/gts-report_$PROJECT/test_result_$new.xml
				echo ${pcPassword} | sudo -S cp $GTSresult/$resultpath.zip $HOME_PATH/gts-report_$PROJECT/$resultpath.zip
				echo ${pcPassword} | sudo -S chmod 777 -R $HOME_PATH/gts-report_$PROJECT/
				#echo $PROJECT;echo $SKU;echo $IMAGE_NAME;
				#new=($PROJECT-$SKU-$IMAGE_NAME)
				#echo $new
				#echo ${pcPassword} | sudo -S mkdir $GTSPATH/$new
				#echo ${pcPassword} | sudo -S mv $GTSresult $GTSPATH/$new/
				#echo ${pcPassword} | sudo -S mkdir $GTSPATH/results
				#echo ${pcPassword} | sudo -S chmod 777 -R $GTSPATH/results

					echo done  ----------------------------------------------done
					exit 0
				fi	
		fi	
	#fi
	cnt=$[cnt-1]
 				
done
echo "retry count is full"
GetResult
resultpath=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $7}}')
echo ${pcPassword} | sudo -S mkdir $HOME_PATH/gts-report_$PROJECT
echo ${pcPassword} | sudo -S cp $GTSresult/$resultpath/test_result.xml $HOME_PATH/gts-report_$PROJECT/test_result_$new.xml
echo ${pcPassword} | sudo -S cp $GTSresult/$resultpath.zip $HOME_PATH/gts-report_$PROJECT/$resultpath.zip
echo ${pcPassword} | sudo -S chmod 777 -R $HOME_PATH/gts-report_$PROJECT/
#echo $PROJECT;echo $SKU;echo $IMAGE_NAME;
#new=($PROJECT-$SKU-$IMAGE_NAME)
#echo $new
#echo ${pcPassword} | sudo -S mkdir $GTSPATH/$new
#echo ${pcPassword} | sudo -S mv $GTSresult $GTSPATH/$new/
#echo ${pcPassword} | sudo -S mkdir $GTSPATH/results
#echo ${pcPassword} | sudo -S chmod 777 -R $GTSPATH/results

exit 0
