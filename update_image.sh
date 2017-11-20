#!/bin/bash

DUTSN=$1

MultiFLAG=0

if [ $# = 1 ];then
	echo =================================================================
	echo "flash multiple devices image now"
	echo =================================================================	
	FASTBOOT="./fastboot_8953 -s $DUTSN"
	MultiFLAG=1
else
	echo =================================================================
	echo "flash image now"
	echo =================================================================
	FASTBOOT="./fastboot_8953"
fi



MARCO_PACKAGE_VARIANT_USERDEBUG="userdebug"
MARCO_PACKAGE_VARIANT_FACTORY="eng"
MARCO_PACKAGE_VARIANT_USER="user"

checksum_file=ZE553KL_8953_checksum.txt

get_package_info()
{
	if [ -n "$1" ] ;then
		val=$(cat build_info | grep $1 | tr -d ' ' | cut -d'=' -f2)
		echo -n $val
	fi
}

get_cpu_type()
{
	cpu_type=$(sudo $FASTBOOT getvar cputype 2>&1 | grep cputype | awk '{print $2}')
	echo -n $cpu_type
}

get_project_name()
{
	pro_name=$(sudo $FASTBOOT getvar project 2>&1 | grep project | awk '{print $2}')
	echo -n $pro_name
}

get_package_project_name()
{
	package_product=$(cat build_info | grep TARGET_PRODUCT | tr -d ' ' | cut -d'=' -f2)

	if [ "$package_product" == "Z01M" ];then
		package_project="ZD552KL_PHOENIX"
	elif [ "$package_product" == "Z018" ];then
		package_project="ZS550KL"
	elif [ "$package_product" == "Z01H" ];then
		package_project="ZE553KL"
	else
		package_project="UNKNOWN PROJECT"
	fi

	echo -n $package_project
}

if [ -z $PACKAGE_VARIANT ];then
	PACKAGE_VARIANT=$(get_package_info TARGET_BUILD_VARIANT)
fi

PACKAGE_TARGET_SKU=$(get_package_info TARGET_SKU)
PROJECT_NAME=$(get_project_name)
IMAGE_PROJECT_NAME=$(get_package_project_name)
CPU_TYPE=$(get_cpu_type)
echo "================================================"
echo "package version: $PACKAGE_VARIANT"
echo "project name:    $PROJECT_NAME"
echo "package sku:     $PACKAGE_TARGET_SKU"
echo "================================================"

if [ "$PROJECT_NAME" != "$IMAGE_PROJECT_NAME" ]; then
    echo "Project different, DO NOT use update_image.sh directly!"
    echo "You Can contact BSP Project Team for help"
	exit 1
fi

echo "flash image now"
echo "================================================"

function GetProject()
{
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZE553KL"
if [ $? -eq 0 ]; then
    project=ZE553KL
fi
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZS550KL"
if [ $? -eq 0 ]; then
    project=ZS550KL
fi
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZD552KL_PHOENIX"
if [ $? -eq 0 ]; then
    project=ZD552KL_PHOENIX
fi

sudo $FASTBOOT getvar project 2>&1
}

GetProject


if [ -n "$project" ]; then
	echo Current project type is $project
else
	echo "cannot get project!!!error!!!"
	exit 1
fi 


# ======================= partition ============================
sudo $FASTBOOT flash partition gpt_both0.bin
if [ $? != 0 ]; then
    exit 1
fi 

# ======================= reboot-bootloader ===========================
sudo $FASTBOOT erase aboot
sudo $FASTBOOT flash aboot emmc_appsboot_8953.mbn
if [ $? != 0 ]; then
    exit 1
fi
echo "reboot:$FASTBOOT reboot-bootloader ...."
sudo $FASTBOOT  reboot-bootloader
if [ $? != 0 ]; then
    exit 1
fi

# ===================== flash: SBL & SBLBAK ==========================
echo "Start Flash SBL & SBLBAK "
sudo $FASTBOOT erase sbl1
sudo $FASTBOOT flash sbl1 firmware/sbl1.mbn
if [ $? != 0 ]; then
    exit 1
fi

sudo $FASTBOOT oem checksum sbl1
if [ $? = 0 ]; then
	checksum_ref=$(grep "sbl1" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum sbl1 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check sbl1: OK"
	else
		echo "check sbl1: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum sbl1
		exit 1
	fi
fi
#########################################################################################################################


sudo $FASTBOOT erase sbl1bak
sudo $FASTBOOT flash sbl1bak firmware/sbl1.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: RPM & RPMBAK ========================
echo "Start Flash RPM & RPMBAK"
sudo $FASTBOOT erase rpm
sudo $FASTBOOT flash rpm firmware/rpm.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum rpm
if [ $? = 0 ]; then
	checksum_ref=$(grep "rpm" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum rpm 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`
	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check rpm: OK"
	else
		echo "check rpm: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum rpm
		exit 1
	fi
fi	
#########################################################################################################################

sudo $FASTBOOT erase rpmbak
sudo $FASTBOOT flash rpmbak firmware/rpm.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: TZ & TZBAK =====================================
echo "Start Flash TZ & TZBAK"
sudo $FASTBOOT erase tz
sudo $FASTBOOT flash tz firmware/tz.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum tz
if [ $? = 0 ]; then
	checksum_ref=$(grep "tz" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum tz 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check tz: OK"
	else
		echo "check tz: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum tz
		exit 1
	fi
fi	
#########################################################################################################################

sudo $FASTBOOT erase tzbak
sudo $FASTBOOT flash tzbak firmware/tz.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: devcfg & devcfgbak =========================
echo "Start Flash devcfg & devcfgbak "
sudo $FASTBOOT erase devcfg
sudo $FASTBOOT flash devcfg firmware/devcfg.mbn
if [ $? != 0 ]; then
	    exit 1
fi
sudo $FASTBOOT oem checksum devcfg
if [ $? = 0 ]; then
	checksum_ref=$(grep "devcfg" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum devcfg 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check devcfg: OK"
	else
		echo "check devcfg: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum devcfg
		exit 1
	fi
fi	
#########################################################################################################################

sudo $FASTBOOT erase devcfgbak
sudo $FASTBOOT flash devcfgbak firmware/devcfg.mbn
if [ $? != 0 ]; then
	    exit 1
fi

# ======================= flash: dsp  =========================================
echo "Start Flash dsp"
sudo $FASTBOOT erase dsp
sudo $FASTBOOT flash dsp firmware/adspso.bin
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: aboot & abootbak =============================
echo "Start Flash aboot & abootbak"
sudo $FASTBOOT erase aboot 
sudo $FASTBOOT flash aboot emmc_appsboot_8953.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum aboot
if [ $? = 0 ]; then
	checksum_ref=$(grep "aboot" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum aboot 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check aboot: OK"
	else
		echo "check aboot: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum aboot
		exit 1
	fi
fi	
#########################################################################################################################

sudo $FASTBOOT erase abootbak 
sudo $FASTBOOT flash abootbak emmc_appsboot_8953.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: lksecapp & clksecappbak  =======================
echo "Start Flash lksecapp & clksecappbak "
sudo $FASTBOOT erase lksecapp
sudo $FASTBOOT flash lksecapp firmware/lksecapp.mbn
if [ $? != 0 ]; then
    exit 1
fi

sudo $FASTBOOT erase lksecappbak
sudo $FASTBOOT flash lksecappbak firmware/lksecapp.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: cmnlib & cmnlibbak  ==========================
echo "Start Flash cmnlib & cmnlibbak "
sudo $FASTBOOT erase cmnlib
sudo $FASTBOOT flash cmnlib firmware/cmnlib.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum cmnlib
if [ $? = 0 ]; then
	checksum_ref=$(grep "cmnlib" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum cmnlib 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`
	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check cmnlib: OK"
	else
		echo "check cmnlib: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum cmnlib
		exit 1
	fi
fi	
#########################################################################################################################

sudo $FASTBOOT erase cmnlibbak
sudo $FASTBOOT flash cmnlibbak firmware/cmnlib.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: cmnlib64 & cmnlib64bak =====================
echo "Start Flash cmnlib64 & cmnlib64bak"
sudo $FASTBOOT erase cmnlib64
sudo $FASTBOOT flash cmnlib64 firmware/cmnlib64.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum cmnlib64
if [ $? = 0 ]; then
	checksum_ref=$(grep "cmnlib64" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum cmnlib64 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check cmnlib64: OK"
	else
		echo "check cmnlib64: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum cmnlib64
		exit 1
	fi
fi
#########################################################################################################################

sudo $FASTBOOT erase cmnlib64bak
sudo $FASTBOOT flash cmnlib64bak firmware/cmnlib64.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: keymaster & keymasterbak ===================
echo "Start Flash keymaster & keymasterbak "
sudo $FASTBOOT erase keymaster
sudo $FASTBOOT flash keymaster firmware/keymaster.mbn
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum keymaster
if [ $? = 0 ]; then
	checksum_ref=$(grep "keymaster" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum keymaster 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check keymaster: OK"
	else
		echo "check keymaster: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum keymaster
		exit 1
	fi
fi	
#########################################################################################################################


sudo $FASTBOOT erase keymasterbak
sudo $FASTBOOT flash keymasterbak firmware/keymaster.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: splash =====================================
echo "Start Flash splash"
sudo $FASTBOOT erase splash
sudo $FASTBOOT flash splash ./splash.bin
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: Modem ==================================
echo "Start Flash Modem"
sudo $FASTBOOT erase modem
sudo $FASTBOOT flash modem modem/NON-HLOS.bin
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum modem
if [ $? = 0 ]; then
	checksum_ref=$(grep "modem" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum modem 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check modem: OK"
	else
		echo "check modem: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum modem
		exit 1
	fi
fi	
	#########################################################################################################################

# ======================= flash: Kernel =================================
echo "Start Flash boot"
sudo $FASTBOOT erase boot
sudo $FASTBOOT flash boot boot.img
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum boot
if [ $? = 0 ]; then
	checksum_ref=$(grep "boot" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum boot 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check boot: OK"
	else
		echo "check boot: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum boot
		exit 1
	fi
fi	
#########################################################################################################################

# ======================= flash: Recovery ===============================
echo "Start Flash Recovery"
sudo $FASTBOOT erase recovery
sudo $FASTBOOT flash recovery recovery.img
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum recovery
if [ $? = 0 ]; then
	checksum_ref=$(grep "recovery" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum recovery 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check recovery: OK"
	else
		echo "check recovery: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum recovery
		exit 1
	fi
fi	
#########################################################################################################################

# ======================= flash: system ================================
echo "Start Flash system"
sudo $FASTBOOT erase system
sudo $FASTBOOT flash system system.img
if [ $? != 0 ]; then
    exit 1
fi
sudo $FASTBOOT oem checksum system
if [ $? = 0 ]; then
	checksum_ref=$(grep "system" -w ZE553KL_8953_checksum.txt | tr : " " | awk '{print $2}')
	checksum=`sudo $FASTBOOT oem checksum system 2>&1`
	checksum=`echo "$checksum" | grep CRC`
	checksum=${checksum##*CRC*:}
	checksum=`echo $checksum`

	if [ "$checksum"x == "$checksum_ref"x ];then
		echo "check system: OK"
	else
		echo "check system: not matched -- current checksum: $checksum vs reference checksum: $checksum_ref"
		echo "fail"
		sudo $FASTBOOT oem fail_checksum system
		exit 1
	fi
fi
#########################################################################################################################

# ======================= flash: apdp & msadp ======================================
if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_USER" ]; then
	echo "================================================"
	echo "Shipping user Build, So Erase apdp & msadp "
	echo "================================================"
	sudo $FASTBOOT erase apdp
	sudo $FASTBOOT erase msadp
else
	echo "================================================"
	echo "Non User Build, So Start Flash apdp & msadp"
	echo "================================================"
	sudo $FASTBOOT erase apdp
	sudo $FASTBOOT flash apdp firmware/apdp.mbn
	if [ $? != 0 ]; then
 	   exit 1
	fi
	sudo $FASTBOOT erase msadp
	sudo $FASTBOOT flash msadp firmware/msadp.mbn
	if [ $? != 0 ]; then
 	   exit 1
	fi
fi

# ======================= format: cache & userdata ===========================
echo "format: cache & userdata ...."
sudo $FASTBOOT -w
if [ $? != 0 ]; then
    exit 1
fi

# =================================================================

if [ $MultiFLAG -eq 1 ] ;then
	echo ======================================
	echo "flash Images Done ! Send OEM Command CTS_Auto 1"
	echo ======================================
	sudo $FASTBOOT oem CTS_Auto 1
	sleep 1
	echo ======================================
	echo "Send OEM Command Done ! Wait for Reboot!"
	echo ======================================
	sleep 3
	
	sudo $FASTBOOT reboot
else
	echo ====================
	echo "flash Images Done !"
	echo ====================
	echo Press any key to continue, system will reboot.
	read
	sudo $FASTBOOT reboot
fi


