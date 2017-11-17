#!/bin/bash

MARCO_PACKAGE_VARIANT_USERDEBUG="userdebug"
MARCO_PACKAGE_VARIANT_FACTORY="eng"
MARCO_PACKAGE_VARIANT_USER="user"

get_package_info()
{
	if [ -n "$1" ] ;then
		val=$(cat build_info | grep $1 | tr -d ' ' | cut -d'=' -f2)
		echo -n $val
	fi
}

get_cpu_type()
{
	cpu_type=$(sudo ./fastboot_8953 getvar cputype 2>&1 | grep cputype | awk '{print $2}')
	echo -n $cpu_type
}

get_project_name()
{
	pro_name=$(sudo ./fastboot_8953 getvar project 2>&1 | grep project | awk '{print $2}')
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

echo =================================================================
echo "flash image now"
echo =================================================================
FASTBOOT="sudo ./fastboot_8953 -s $1"

function GetProject()
{
$FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZE553KL"
if [ $? -eq 0 ]; then
    project=ZE553KL
fi
$FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZD552KL_PHOENIX"
if [ $? -eq 0 ]; then
    project=ZD552KL_PHOENIX
fi
$FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZS550KL"
if [ $? -eq 0 ]; then
    project=ZS550KL
fi
}

GetProject

if [ -n "$project" ]; then
	echo Current project type is $project
else
	echo "cannot get project!!!error!!!"
	exit 1
fi 


# ======================= partition ============================
$FASTBOOT flash partition gpt_both0.bin
if [ $? != 0 ]; then
    exit 1
fi 

# ======================= BootLoader ============================
$FASTBOOT erase sbl1
$FASTBOOT flash sbl1 firmware/sbl1.mbn
if [ $? != 0 ]; then
    exit 1
fi
# ======================= RPM ====================================
$FASTBOOT erase rpm
$FASTBOOT flash rpm firmware/rpm.mbn
if [ $? != 0 ]; then
    exit 1
fi
# ======================= TZ =====================================
$FASTBOOT erase tz
$FASTBOOT flash tz firmware/tz.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= devcfg =====================================
$FASTBOOT erase devcfg
$FASTBOOT flash devcfg firmware/devcfg.mbn
if [ $? != 0 ]; then
	    exit 1
fi

# ======================= dsp =====================================
$FASTBOOT erase dsp
$FASTBOOT flash dsp firmware/adspso.bin
if [ $? != 0 ]; then
    exit 1
fi


# ======================= lksecapp =====================================
$FASTBOOT erase lksecapp
$FASTBOOT flash lksecapp firmware/lksecapp.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= cmnlib =====================================
$FASTBOOT erase cmnlib
$FASTBOOT flash cmnlib firmware/cmnlib.mbn
if [ $? != 0 ]; then
	    exit 1
	    fi


# ======================= cmnlib64 =====================================
$FASTBOOT erase cmnlib64
$FASTBOOT flash cmnlib64 firmware/cmnlib64.mbn
if [ $? != 0 ]; then
	    exit 1
fi

# ======================= keymaster =====================================
$FASTBOOT erase keymaster
$FASTBOOT flash keymaster firmware/keymaster.mbn
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= splash =====================================
$FASTBOOT erase splash
$FASTBOOT flash splash firmware/splash.bin
if [ $? != 0 ]; then
    exit 1
fi

# ======================= apdp ======================================
$FASTBOOT erase apdp
$FASTBOOT flash apdp firmware/apdp.mbn
if [ $? != 0 ]; then
	            return 1
fi

# ======================= msadp ======================================
$FASTBOOT erase msadp
$FASTBOOT flash msadp firmware/msadp.mbn
if [ $? != 0 ]; then
	            return 1
fi

# ======================= aboot =====================================
$FASTBOOT erase aboot 
$FASTBOOT flash aboot emmc_appsboot_8953.mbn
if [ $? != 0 ]; then
	    exit 1
	    fi

# ======================= Modem ==================================
$FASTBOOT erase modem
echo "modem/$project/NON-HLOS-64bit.bin"
$FASTBOOT flash modem modem/NON-HLOS.bin
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= asdf ==================================
$FASTBOOT erase asdf
$FASTBOOT flash asdf asdf.img
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= Kernel =================================
$FASTBOOT erase boot
$FASTBOOT flash boot boot.img
if [ $? != 0 ]; then
    exit 1
fi

# ======================= Recovery ===============================
$FASTBOOT erase recovery
$FASTBOOT flash recovery recovery.img
if [ $? != 0 ]; then
    exit 1
fi

# ======================= flash: apdp & msadp ======================================
if [ "$PACKAGE_VARIANT" = "$MARCO_PACKAGE_VARIANT_USER" ]; then
	echo "================================================"
	echo "Shipping user Build, So Erase apdp & msadp "
	echo "================================================"
	sudo ./fastboot_8953 erase apdp
	sudo ./fastboot_8953 erase msadp
else
	echo "================================================"
	echo "Non User Build, So Start Flash apdp & msadp"
	echo "================================================"
	sudo ./fastboot_8953 erase apdp > /dev/null 2>&1
	sudo ./fastboot_8953 flash apdp firmware/apdp.mbn
	if [ $? != 0 ]; then
 	   exit 1
	fi
	sudo ./fastboot_8953 erase msadp > /dev/null 2>&1
	sudo ./fastboot_8953 flash msadp firmware/msadp.mbn
	if [ $? != 0 ]; then
 	   exit 1
	fi
fi

# ======================= format: cache & userdata ===========================
echo "format: cache & userdata ...."
sudo ./fastboot_8953 -w
if [ $? != 0 ]; then
    exit 1
fi

# =================================================================
echo ====================
echo "flash Images Done !"
echo ====================
echo "set up oem adb_enable for test"
$FASTBOOT oem adb_enable
echo "reboot device"
$FASTBOOT reboot

exit 0

