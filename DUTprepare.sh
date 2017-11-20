#!/bin/bash
HOME_PATH=~/Desktop/Image/
testpath=$1
pcPassword=$2
PROJECT=$3
SKU=$4
#DUTSIM=$5
cd $testpath
phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}') #get devices number
echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}' > $testpath/Serialnumber.txt   #get Serial number
for ((i=1;i<=$phonenumber;i++))
	do
	echo ${pcPassword} | sudo -S touch $testpath/$i.sh
	echo ${pcPassword} | sudo -S chmod 777 $testpath/$i.sh
	echo "#!/bin/bash" > $i.sh
	echo "export testpath=$testpath"  >> $testpath/$i.sh
	DUTSN=$(echo | awk ''NR==$i'{print}' $testpath/Serialnumber.txt)
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
	echo "cd  $testpath" >> $testpath/$i.sh
	echo "adb -s $DUTSN push $testpath/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard" >> $testpath/$i.sh
	echo "sleep 5" >> $testpath/$i.sh
	echo "adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"" >> $testpath/$i.sh
	echo "sleep 5" >> $testpath/$i.sh
	echo "adb -s $DUTSN push $testpath/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test" >> $testpath/$i.sh
	echo "sleep 5" >> $testpath/$i.sh
	echo "adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"" >> $testpath/$i.sh
	echo "sleep 5" >> $testpath/$i.sh
	echo "adb -s $DUTSN shell am instrument -w -r -e project $PROJECT -e sku $SKU -e sim $DUTSIM -e debug false -e class com.tdc.cts.skipsetupwizard.ExampleInstrumentedTest  com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner" >> $testpath/$i.sh
	echo "exit 0" >> $testpath/$i.sh
done

echo ${pcPassword} | sudo -S touch  $testpath/skipandprepare.sh
echo ${pcPassword} | sudo -S chmod 777 $testpath/skipandprepare.sh
echo "#!/bin/bash" > $testpath/skipandprepare.sh
for ((i=1;i<$phonenumber;i++))
	do
	echo "sh $i.sh &" >> $testpath/skipandprepare.sh
done
echo "sh $phonenumber.sh " >> $testpath/skipandprepare.sh
echo "wait" >> $testpath/skipandprepare.sh
echo "exit 0" >> $testpath/skipandprepare.sh
cd $testpath
echo | ./skipandprepare.sh
echo =======Set done===========
sleep 3
echo ${pcPassword} | sudo -S rm *.sh
echo "Prepare DUT done"
exit 0
