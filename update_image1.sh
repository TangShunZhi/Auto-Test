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


function GetProject()
{
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZE553KL"
if [ $? -eq 0 ]; then
    project=ZE553KL
fi
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZD552KL"
if [ $? -eq 0 ]; then
    project=ZD552KL
fi
sudo $FASTBOOT getvar project 2>&1 | grep "project" | grep -q "ZS550KL"
if [ $? -eq 0 ]; then
    project=ZS550KL
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

# ======================= BootLoader ============================
echo "skip Flash BootLoader...sbl/tz/rpm/aboot"
sudo $FASTBOOT erase sbl1
sudo $FASTBOOT flash sbl1 firmware/sbl1.mbn
if [ $? != 0 ]; then
    exit 1
fi
# ======================= RPM ====================================
echo "skip Flash BootLoader...sbl/tz/rpm/aboot"
sudo $FASTBOOT erase rpm
sudo $FASTBOOT flash rpm firmware/rpm.mbn
if [ $? != 0 ]; then
    exit 1
fi
# ======================= TZ =====================================
echo "skip Flash BootLoader...sbl/tz/rpm/aboot"
sudo $FASTBOOT erase tz
sudo $FASTBOOT flash tz firmware/tz.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= devcfg =====================================
echo "skip Flash BootLoader...sbl/tz/rpm/aboot"
sudo $FASTBOOT erase devcfg
sudo $FASTBOOT flash devcfg firmware/devcfg.mbn
if [ $? != 0 ]; then
	    exit 1
fi

# ======================= dsp =====================================
echo "skip Flash BootLoader...sbl/tz/rpm/aboot"
sudo $FASTBOOT erase dsp
sudo $FASTBOOT flash dsp firmware/adspso.bin
if [ $? != 0 ]; then
    exit 1
fi


# ======================= lksecapp =====================================
sudo $FASTBOOT erase lksecapp
sudo $FASTBOOT flash lksecapp firmware/lksecapp.mbn
if [ $? != 0 ]; then
    exit 1
fi

# ======================= cmnlib =====================================
sudo $FASTBOOT erase cmnlib
sudo $FASTBOOT flash cmnlib firmware/cmnlib.mbn
if [ $? != 0 ]; then
	    exit 1
	    fi


# ======================= cmnlib64 =====================================
sudo $FASTBOOT erase cmnlib64
sudo $FASTBOOT flash cmnlib64 firmware/cmnlib64.mbn
if [ $? != 0 ]; then
	    exit 1
fi

# ======================= keymaster =====================================
sudo $FASTBOOT erase keymaster
sudo $FASTBOOT flash keymaster firmware/keymaster.mbn
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= splash =====================================
sudo $FASTBOOT erase splash
sudo $FASTBOOT flash splash ./splash.bin
if [ $? != 0 ]; then
    exit 1
fi

# ======================= apdp ======================================
echo "erase apdp"
sudo $FASTBOOT erase apdp
sudo $FASTBOOT flash apdp firmware/apdp.mbn
if [ $? != 0 ]; then
	            return 1
fi

# ======================= msadp ======================================
echo "erase msadp"
sudo $FASTBOOT erase msadp
sudo $FASTBOOT flash msadp firmware/msadp.mbn
if [ $? != 0 ]; then
	            return 1
fi

# ======================= aboot =====================================
echo "Flash BootLoader"
sudo $FASTBOOT erase aboot 
sudo $FASTBOOT flash aboot emmc_appsboot_8953.mbn
if [ $? != 0 ]; then
	    exit 1
	    fi

# ======================= Modem ==================================
echo "Flash modem..."
sudo $FASTBOOT erase modem
echo "modem/$project/NON-HLOS-64bit.bin"
sudo $FASTBOOT flash modem modem/$project/NON-HLOS.bin
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= asdf ==================================
echo "Flash asdf..."
sudo $FASTBOOT erase asdf
sudo $FASTBOOT flash asdf asdf.img
if [ $? != 0 ]; then
	            exit 1
		    fi

# ======================= Kernel =================================
echo "Flash kernel..."
sudo $FASTBOOT erase boot
sudo $FASTBOOT flash boot boot.img
if [ $? != 0 ]; then
    exit 1
fi
# ======================= cache  =================================
echo "Flash kernel..."
sudo $FASTBOOT erase cache
sudo $FASTBOOT flash cache cache.img
if [ $? != 0 ]; then
    exit 1
fi
# ======================= Recovery ===============================
echo "Flash Recovery..."
sudo $FASTBOOT erase recovery
sudo $FASTBOOT flash recovery recovery.img
if [ $? != 0 ]; then
    exit 1
fi

# ======================= system ================================
echo "Flash system..."

sudo $FASTBOOT erase system
sudo $FASTBOOT flash system system.img
if [ $? != 0 ]; then
    exit 1
fi

# ======================= format userdata ===============================
echo "format userdata"
sudo $FASTBOOT erase userdata
sudo $FASTBOOT format:ext4 userdata
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


