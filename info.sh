#!/bin/bash

PROJECT=$1

FILE=info_$PROJECT.txt

echo >$FILE
echo ==============================>>$FILE
echo =======collect OA info========>>$FILE
echo ==============================>>$FILE
date >>$FILE
echo >>$FILE


echo ====="get ubuntu version"===== >>$FILE
echo >>$FILE
sudo lsb_release -a  >>$FILE
echo >>$FILE
echo ====="get kernel version"===== >>$FILE
echo >>$FILE
uname -r >>$FILE
echo >>$FILE
echo ====="get java version"===== >>$FILE
echo >>$FILE
java -version &>>$FILE 
echo >>$FILE
echo ====="get MB/NB type"===== >>$FILE
echo >>$FILE
sudo dmidecode -s baseboard-product-name >>$FILE
echo >>$FILE
echo ====="get cpu type"===== >>$FILE
echo >>$FILE
cat /proc/cpuinfo | grep "model name" >>$FILE
echo >>$FILE
echo ====="get memory size"===== >>$FILE
echo >>$FILE
free -h >>$FILE
echo >>$FILE
echo ====="get usb info"===== >>$FILE
echo >>$FILE
echo ====="lsusb"===== >>$FILE
lsusb >>$FILE
echo ====="lsusb -t"===== >>$FILE
lsusb -t &>>$FILE
echo ====="lsusb -v"===== >>$FILE
lsusb -v &>>$FILE
echo >>$FILE
echo ====="get lan info"===== >>$FILE
echo >>$FILE
ifconfig >>$FILE
echo >>$FILE

echo ==============================>>$FILE
echo =======collect dut info=======>>$FILE
echo ==============================>>$FILE
echo >>$FILE

Num=`sed -n '$=' DUTSN_$PROJECT`
#Num=$[$Num - 1]
echo === $Num devices found ===>>$FILE
echo >>$FILE
sleep 1

echo ====="get SDCard info"=====>>$FILE 

for dutsn in $(cat ./DUTSN_$PROJECT)
do
echo DUT is $dutsn >>$FILE
echo >>$FILE
adb -s $dutsn shell mount | grep "/dev/block/vold/public" >>$FILE
done

echo ====="get SIM info"=====>>$FILE 
for dutsn in $(cat ./DUTSN_$PROJECT)
do
echo DUT is $dutsn >>$FILE
echo >>$FILE
adb -s $dutsn shell getprop | grep "gsm.sim.state" >>$FILE
done

echo >>$FILE
echo ==============================>>$FILE
echo =======collect done===========>>$FILE
echo ==============================>>$FILE




