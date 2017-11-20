export CTSPATH=~/android-cts/7.1r6/android-cts
export CTStool=$CTSPATH/tools/
export CTSresult=$CTSPATH/results/
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
export ANDROID_JAVA_HOME=$JAVA_HOME
#./cts-tradefed
export cnt=10
export usedsession=0

GetPhoneNumber(){
	phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}')

}

GetResult(){	
	echo | $CTStool/cts-tradefed l r | awk '/of/{print}' > result.txt	
	ResultNumber=$(echo | cat -n result.txt | awk 'END{print $1}')
        SessionID=$(echo | cat result.txt | awk 'END{print $1}')
	resultpath=$(echo | cat result.txt | awk 'END{print $7}')
        echo SessionID is $SessionID
	echo Resultpat is $resultpath
}

GetSim(){
        phonesn=$(echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}')
#	echo $phonesn
	for var in $phonesn; do
#		echo $var
   		sim1=$(echo | adb -s $var shell getprop gsm.sim1.present)
		if [ $sim1 -eq 1 ]; then
			simsn="--device-token $var:sim-card"
			DWS=$var
		fi
                sim2=$(echo | adb -s $var shell getprop gsm.sim2.present)
                if [ $sim2 -eq 1 ]; then
                        simsn="--device-token $var:sim-card"
			DWS=$var
                fi
	done
}


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
	echo | $CTStool/cts-tradefed run cts -o -a arm64-v8a --shards $phonenumber $simsn 

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
	resultpath=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $8}}')
	echo $resultpath
	awk -f ctsn.awk $CTSresult/$resultpath/test_result.xml   >$CTSresult/$resultpath/test_result_new.xml
	mv $CTSresult/$resultpath/test_result_new.xml  $CTSresult/$resultpath/test_result.xml
        result1pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result1fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result1notexcute=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
	echo now we will retry $cnt times; 
	echo retry session $SessionID
        echo | $CTStool/cts-tradefed run cts -o -r $SessionID --shards $phonenumber $simsn
	GetResult
        result2pass=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $2}}') 
        result2fail=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $3}}') 
        result2notexcute=$(echo | $CTStool/cts-tradefed l r | awk -v sessionIDs="$SessionID" 'BEGIN{ } {if($1==sessionIDs) {print $4}}') 
        echo $result1pass $result1fail $result1notexcute 
	echo $result2pass $result2fail $result2notexcute SessionID=$SessionID
	#if [ $result2notexcute -eq 0 ]; then
		if [ $result1pass -eq $result2pass ]; then	
				if [ $result1fail -eq $result2fail ]; then	
					GetResult
					echo | $CTStool/cts-tradefed run cts -o -r $SessionID -s $DWS
					sleep 10
					echo done  --------------------------------------done
					exit 0
				fi	
		fi	
	#fi
	cnt=$[cnt-1]
done
GetResult
echo | $CTStool/cts-tradefed run cts -o -r $SessionID -s $DWS
sleep 10
echo done  --------------------------------------done
exit 0
