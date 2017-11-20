#!/bin/bash
HOME_PATH=~/Desktop/Image/
DUTSN=$1
pcPassword=$2
PROJECT=$3
SKU=$4

#DUTSN=$(echo | awk ''NR==$i'{print}' $testpath/Serialnumber.txt)
echo " ===== Check SIM ===== "
sim1=$(echo | adb -s $DUTSN shell getprop gsm.sim1.present)
sim2=$(echo | adb -s $DUTSN shell getprop gsm.sim2.present)
if [ $sim1 -eq 1 ] || [ $sim2 -eq 1 ] ; then
         DUTSIM=yes
         echo " ===== YES SIM ===== "
  	 else
         DUTSIM=no
         echo " ===== No SIM ===== "
         fi

adb -s $DUTSN push $testpath/app-debug.apk /data/local/tmp/com.tdc.cts.skipsetupwizard
sleep 5
adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard"
sleep 5
adb -s $DUTSN push $testpath/app-debug-androidTest.apk /data/local/tmp/com.tdc.cts.skipsetupwizard.test/$i.sh
sleep 5
adb -s $DUTSN shell pm install -r "/data/local/tmp/com.tdc.cts.skipsetupwizard.test"
sleep 5
adb -s $DUTSN shell am instrument -w -r -e project $PROJECT -e sku $SKU -e sim $DUTSIM -e debug false -e class com.tdc.cts.skipsetupwizard.ExampleInstrumentedTest  com.tdc.cts.skipsetupwizard.test/android.support.test.runner.AndroidJUnitRunner
exit 0


echo " ===== Set done ===== "
sleep 3
exit 0
