#!/bin/bash


CTS_PATH=~/android-cts
HOME_PATH=~/Desktop/Image

rm -rf $HOME_PATH/tmp
rm -rf $HOME_PATH/tmp2
rm -rf $HOME_PATH/tmp3
rm -rf $HOME_PATH/CTS71

cd $CTS_PATH
ls -l > $HOME_PATH/tmp
awk '$1~/d/{print $1,$9}' $HOME_PATH/tmp  >$HOME_PATH/tmp2
awk '$2~/7.1r/{print $2}' $HOME_PATH/tmp2 >$HOME_PATH/CTS71
#awk '$2~/7.0r/{print $2}' $HOME_PATH/tmp2 >>$HOME_PATH/CTS71

#cat $HOME_PATH/CTS71


for ctsver in $(cat $HOME_PATH/CTS71)
do
  CTSTOOL_PATH=$CTS_PATH/$ctsver/android-cts/tools
  echo get $ctsver result 
  echo | $CTSTOOL_PATH/cts-tradefed l r >$HOME_PATH/tmp3

  if [[ $ctsver == "7.1r5" ]]  ;then
	awk '$5~/of/{print $0}' $HOME_PATH/tmp3 >$HOME_PATH/ctsresult_$ctsver
	awk '{print $7}' $HOME_PATH/ctsresult_$ctsver > $HOME_PATH/resultpath_$ctsver
  else
  	awk '$6~/of/{print $0}' $HOME_PATH/tmp3 >$HOME_PATH/ctsresult_$ctsver
	awk '{print $8}' $HOME_PATH/ctsresult_$ctsver > $HOME_PATH/resultpath_$ctsver
  fi

  rm -rf $HOME_PATH/tmp_$ctsver
  sleep 1
  touch $HOME_PATH/tmp_$ctsver


  for resultpath in $(cat $HOME_PATH/resultpath_$ctsver)
  do       
	if [ ! -f "$CTS_PATH/$ctsver/android-cts/results/$resultpath/device-info-files/GenericDeviceInfo.deviceinfo.json" ]; then
            echo "$ctsver: $resultpath Not Find GenericDeviceInfo.deviceinfo.json"
        else
	    fingerprint=$(echo | awk '$0~/build_fingerprint/{print $2}' $CTS_PATH/$ctsver/android-cts/results/$resultpath/device-info-files/GenericDeviceInfo.deviceinfo.json) 
	    buildversion=$(echo $fingerprint | awk -F / '{print $5}' )
            echo | awk -v cv=$ctsver -v fp=$buildversion -v cv=$ctsver '$0~/'$resultpath'/{printf "%-10s\t%s\t%-40s\n",cv,$0,fp}' $HOME_PATH/ctsresult_$ctsver >>$HOME_PATH/tmp_$ctsver            
        fi
  done
  
  awk '{
      if($0~/Z01M/){print $0,"Phoenix"}
      else if($0~/Z01H/){print $0,"Hades"}
      else if($0~/Z01B/){print $0,"Scorpio"}
      else if($0~/Z01F/){print $0,"Aquarius"}
      else {print $0,"Unkown"}
    }' $HOME_PATH/tmp_$ctsver > $HOME_PATH/CTSResultReport_$ctsver


done



for ctsver in $(cat $HOME_PATH/CTS71)
do
	echo get $ctsver detail fail

	rm -rf $HOME_PATH/detail_tmp1
	rm -rf $HOME_PATH/detail_tmp2

	for resultpath in $(cat $HOME_PATH/resultpath_$ctsver)
	do
        
        	awk -F '[<>]+' -v cv=$ctsver -v rp=$resultpath '$0~/testname/{printf "%-10s%-25s%-100s\n",cv,rp,$3}' $CTS_PATH/$ctsver/android-cts/results/$resultpath/test_result_failures.html >> $HOME_PATH/detail_tmp1
   		awk -F '[<>]+' '$0~/class="details"/{print $3}' $CTS_PATH/$ctsver/android-cts/results/$resultpath/test_result_failures.html >> $HOME_PATH/detail_tmp2    	 
	done

	paste $HOME_PATH/detail_tmp1 $HOME_PATH/detail_tmp2 > $HOME_PATH/CTSDetail_$ctsver

done








