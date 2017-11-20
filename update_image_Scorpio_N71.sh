#!/bin/bash
#MARCO_DEFINE
FASTBOOT_BIN=./fastboot_8937
MARCO_PACKAGE_VARIANT_USERDEBUG="userdebug"
MARCO_PACKAGE_VARIANT_FACTORY="fac"
MARCO_PACKAGE_VARIANT_USER="user"
#GLOBAL DEFINE
SHIPPING_FLASHED=""
ERASE_DATA_CACHE=""
PACKAGE_VARIANT=""
PROJECT_NAME=""
CPU_TYPE=""
PACKAGE_TARGET_SKU=""
FAIL_MESSAGE="fail"
PASS_MESSAGE="pass"
UPDATE_SCRIPT_NAME=""
MULTI_DEVICES_UPDATE="1"
#usage
usage(){
 echo "usage update_image.sh [-w] | [-s] | [-h]"
 echo " -w                      erase userdata and cache"
 echo " --shipping         shipping update image  "
 echo " -h | --help             print usage message "
 echo "-s  		  flash image for device with serial number"
}
#get information from the document build_info
#call: get_package_info TARGET_BUILD_VARIANT, to get package version
get_package_info(){
  if [ -n "$1" ] ;then
        val=$(cat build_info | grep $1 | cut -d "=" -f2)
        echo -n $val
  fi
}
#get cputype by fastboot getvar cputype
get_cpu_type(){
  cpu_type=$(sudo $FASTBOOT_BIN getvar cputype 2>&1 | grep "cputype:" | cut -d " " -f2 | tr -d " ")
  echo -n $cpu_type
}
#get porject name by fastboot getvar project
get_project_name(){
  pro_no=$(sudo $FASTBOOT_BIN getvar project 2>&1 | grep "project:" | cut -d " " -f2 | tr -d " ")
  pro_name=""
  case $pro_no in
  12|15|10|11)
	pro_name=ZC551KL
	;;
  13|14)
	pro_name=ZC500KL
	;;
  8|9)
	pro_name=ZC600KL
	;;
  esac
  echo -n $pro_name
}
#erase partition
erase_partition(){
  es_part_lable=$1
  if [ -n "$es_part_lable" ]; then
	sudo $FASTBOOT_BIN erase $es_part_lable
	if [ $? != 0 ]; then
		echo "fail to erase $es_part_lable"
		echo $FAIL_MESSAGE
	    	exit 1
	fi
  else
       echo $FAIL_MESSAGE
       exit 1
  fi
  return 0;
}
#example: flash_partiton system system.img 1
#$1: partion label
#$2: image path
#$3: wheter to erase the partition before flashing
flash_partiton(){
  flash_part_lable=$1
  flash_image_path=$2
  flash_erased=$3
  if [ -z "$flash_part_lable" ]; then
	echo "partition label should not NULL"
        echo $FAIL_MESSAGE
	exit 1
  fi
  if [ -z "$flash_image_path" ]; then
	echo "partition image path should not NULL"
        echo $FAIL_MESSAGE
        exit 1
  fi
  if [ -e $flash_image_path ] ; then
        if [ "$flash_erased" = "1" ]; then
  	   echo "erase parttion: $flash_part_lable"
	   sudo $FASTBOOT_BIN erase $flash_part_lable
           if [ $? != 0 ]; then
		echo "fail to erase $flash_part_lable ,before flashing"
		echo $FAIL_MESSAGE
	    	exit 1
	   fi
  	fi
	echo "flash partiton: $flash_part_lable ,image path: $flash_image_path"
	sudo $FASTBOOT_BIN flash $flash_part_lable $flash_image_path
	if [ $? != 0 ]; then
		echo "fail to flash: $flash_part_lable"
		echo $FAIL_MESSAGE
	    	exit 1
	fi
  else
        echo "$flash_image_path is not exist, when flash $flash_part_lable"
        echo $FAIL_MESSAGE
        exit 1
  fi
  return 0
}
#formate partition
#example call: formate_partition userdata ext4
formate_partition(){
  fmt_part_label=$1
  fmt_part_fs=$2
  sudo $FASTBOOT_BIN format:$fmt_part_fs $fmt_part_label
  if [ $? != 0 ]; then
	echo "formate partition:$fmt_part_label fs:$fmt_part_fs  error"
        echo $FAIL_MESSAGE
	exit 1
  fi
  return 0
}

#=====Main=============================================================
UPDATE_SCRIPT_NAME="US"
while [ "$1" != "" ]; do
    case $1 in
        -w )
         ERASE_DATA_CACHE="1"
         ;;
        -s )
	 shift
	 MULTI_DEVICES_UPDATE="1"
         FASTBOOT_BIN="$FASTBOOT_BIN -s $1"
         ;;
        --shipping)
         SHIPPING_FLASHED="1"
	 UPDATE_SCRIPT_NAME="SS"
         ;;
  	--fac)
         PACKAGE_VARIANT="$MARCO_PACKAGE_VARIANT_FACTORY"
	 UPDATE_SCRIPT_NAME="FS"
         ;;
        -h | --help )
          usage
          exit
          ;;
    esac
    shift
done
#=======get global variant and check package,cpu information====================
if [ -z $PACKAGE_VARIANT ] ; then
PACKAGE_VARIANT=$(get_package_info TARGET_BUILD_VARIANT)
fi
PACKAGE_TARGET_SKU=$(get_package_info TARGET_SKU)
PROJECT_NAME=$(get_project_name)
CPU_TYPE=$(get_cpu_type)
echo "package version: $PACKAGE_VARIANT"
echo "project name: $PROJECT_NAME"
echo "cpu type: $CPU_TYPE"
echo "package sku:$PACKAGE_TARGET_SKU"
if [ "$SHIPPING_FLASHED" = "1" ]; then
  echo "shipping flash"
fi

#check project name and cputype
if [ -z $PROJECT_NAME ]; then
	echo "project is not recognized"
        echo $FAIL_MESSAGE
	exit 1
fi
if [ -z $CPU_TYPE ]; then
	echo "cputype is not recognized"
        echo $FAIL_MESSAGE
	exit 1
fi
#==========erase or flash image==================================================
echo =================================================================
echo "flash image now"
echo =================================================================
#check oem version and then flash partition
sudo $FASTBOOT_BIN oem check_confirm 2>&1 |grep "ABOOT_OEM_VERSION 2"
if [  $? -ne 0 ]; then
    echo "Partition Changed, DO NOT use update_image.sh directly!"
    echo "You Can contact BSP Project Team for help"
else
    echo "flash image now"
OEM_UPDATE_INFO_CMD_STR="oem update-info $UPDATE_SCRIPT_NAME $(whoami) $(hostname)"
#OEM_UPDATE_INFO_CMD_STR=${OEM_UPDATE_INFO_CMD_STR:0:63}
OEM_UPDATE_INFO_CMD_STR=$(echo $OEM_UPDATE_INFO_CMD_STR | awk  '{ str=substr($0,1,63); print str; }' )
sudo $FASTBOOT_BIN $OEM_UPDATE_INFO_CMD_STR
if [  $? -ne 0 ]; then
    echo "Do not support fastboot oem update-info commond"
fi
# ======================= flash: partition firstly===============

    flash_partiton partition firmware/$CPU_TYPE/gpt_both0.bin

# =======================erase: fsc ssd in factory===============================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
      erase_partition fsc
      erase_partition ssd
      erase_partition modemst1
      erase_partition modemst2
      erase_partition DDR
      erase_partition splash
      erase_partition dpo
      erase_partition bootparam
      erase_partition flashlog
      erase_partition sysconf
      erase_partition devinfo
      erase_partition keystore
      erase_partition config
      erase_partition limits
      erase_partition mota
      erase_partition dip
      erase_partition mdtp
      erase_partition syscfg
    fi
#=========================erase: misc in all mode ====================================
    erase_partition misc
# ======================= flash: SBL & SBLBAK in all mode  ============================
    flash_partiton sbl1 firmware/$CPU_TYPE/sbl1.mbn
    flash_partiton sbl1bak firmware/$CPU_TYPE/sbl1.mbn
# ======================= flash: RPM & RPMBAK in all mode =============================
    flash_partiton rpm firmware/$CPU_TYPE/rpm.mbn
    flash_partiton rpmbak firmware/$CPU_TYPE/rpm.mbn
# ======================= flash: TZ & TZBAK in all mode ===============================
    flash_partiton tz firmware/$CPU_TYPE/tz.mbn
    flash_partiton tzbak firmware/$CPU_TYPE/tz.mbn
# ======================= flash: devcfg & devcfgbak in all mode=======================
    flash_partiton devcfg firmware/$CPU_TYPE/devcfg.mbn
    flash_partiton devcfgbak firmware/$CPU_TYPE/devcfg.mbn
# ======================= flash: dsp in all mode ======================================
    flash_partiton dsp firmware/$CPU_TYPE/adspso.bin 1
# ======================= flash:fsg in factory=========================================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
      flash_partiton fsg modem/$PROJECT_NAME/fs_image.tar.gz.mbn.img 1
    fi
# ======================= flash:apdp in userdebug, otherwise erase ====================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_USER" ]; then
      erase_partition apdp
    else
      flash_partiton apdp firmware/$CPU_TYPE/apdp.mbn
    fi
# ======================= flash:msadp in userdebug,otherwise erase =====================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_USER" ]; then
      erase_partition msadp
    else
      flash_partiton msadp firmware/$CPU_TYPE/msadp.mbn
    fi
# ======================= flash: aboot & abootbak in all mode==========================
    flash_partiton aboot emmc_appsboot_${CPU_TYPE}.mbn
    flash_partiton abootbak emmc_appsboot_${CPU_TYPE}.mbn

# ======================= flash: cmnlib & cmnlibbak in all mode========================
    flash_partiton cmnlib firmware/$CPU_TYPE/cmnlib.mbn
    flash_partiton cmnlibbak firmware/$CPU_TYPE/cmnlib.mbn

# ======================= flash: cmnlib64 & cmnlib64bak in all mode====================
    flash_partiton cmnlib64 firmware/$CPU_TYPE/cmnlib64.mbn
    flash_partiton cmnlib64bak firmware/$CPU_TYPE/cmnlib64.mbn
# ======================= flash: keymaster & keymasterbak in all mode==================
    flash_partiton keymaster firmware/$CPU_TYPE/keymaster.mbn
    flash_partiton keymasterbak firmware/$CPU_TYPE/keymaster.mbn
# ======================= flash: factory & factorybak in factory mode==================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
      flash_partiton factory firmware/$CPU_TYPE/factory.img  1
      flash_partiton factorybak firmware/$CPU_TYPE/factory.img 1
    fi
# ======================= formate:ADF & APD formate in factory=========================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
      formate_partition ADF ext4
      formate_partition APD ext4
    fi

# ======================= flash:Modem in all mode=====================================
# =============Modem need erase partiting before flashing============
    flash_partiton modem modem/$PROJECT_NAME/$CPU_TYPE/NON-HLOS.bin 1

# ======================= flash:persist in factory ==================================
    if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
       flash_partiton persist persist.img 1
    fi
# ======================= flash:Kernel in all mode====================================
    flash_partiton boot boot.img

# ======================= flash:Recovery in all mode==================================
    flash_partiton recovery recovery.img

# ======================= flash:system in all mode========================================
# =============need erase before flashing======
    flash_partiton system system.img

# ======================= flash:absolute =================================================
    if [ "$PACKAGE_TARGET_SKU" = "RAC" ]; then
      if [ "$SHIPPING_FLASHED" = "1" -o "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_FACTORY" ]; then
      flash_partiton absolute firmware/$CPU_TYPE/absolute.img 1
      fi
    fi
# =======================erase: userdata & cache with -w option===========================
   if [ "$SHIPPING_FLASHED" = "1" -o  "$ERASE_DATA_CACHE" = "1" ] ;then
      echo "$FASTBOOT_BIN -w"
      sudo $FASTBOOT_BIN -w
      if [ $? != 0 ]; then
	    echo $FAIL_MESSAGE
	    exit 1
      fi
   else
      formate_partition cache ext4
      formate_partition userdata ext4
   fi
#display end information
    echo ====================
    echo "flash Images Done !"
    echo ====================
#reboot system
    if [ "$SHIPPING_FLASHED" = "1" ] ;then
       echo $PASS_MESSAGE
    elif [ "$MULTI_DEVICES_UPDATE" = "1" ]; then
       echo $PASS_MESSAGE
       echo ===Set CTS_Auto command===
       sudo $FASTBOOT_BIN oem CTS_Auto 1
       sleep 1
       sudo $FASTBOOT_BIN reboot
    else
       echo $PASS_MESSAGE
       read -p "Press any key to continue, system will reboot."
       sudo $FASTBOOT_BIN reboot
    fi
fi
