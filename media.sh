#!/bin/bash
export MEDIAPATH=~/Desktop/android-cts/android-cts-media-1.2
phonenumber=$(echo | adb devices | awk 'BEGIN{i=0} ($0~/device/) {++i}END{print i-1}') #get devices number
echo | adb devices | awk 'BEGIN{} ($2~/device/) {print $1} END{}' > Serialnumber.txt   #get Serial number
for ((i=1;i<=$phonenumber;i++))
	do
	echo "#!/bin/bash" > $i.sh
	echo "export MEDIAPATH=~/Desktop/android-cts/android-cts-media-1.2"  >> $i.sh
	sn=$(echo | awk ''NR==$i'{print}' Serialnumber.txt)
	echo "cd  $MEDIAPATH" >> $i.sh
	echo "echo | ./copy_media.sh -s $sn" >> $i.sh
done
echo "#!/bin/bash" > cpmedia.sh
for ((i=1;i<$phonenumber;i++))
	do
	echo "sh $i.sh &" >> cpmedia.sh
done
echo "sh $phonenumber.sh " >> cpmedia.sh
sudo chmod 777 cpmedia.sh
echo | ./cpmedia.sh
echo =======copy done===========
sleep 3
done
sudo rm cpmedia.sh
wait 
