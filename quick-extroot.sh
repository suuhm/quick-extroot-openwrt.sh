#!/bin/sh
#
# --------------------------------
# openwrt : quick-extroot v0.2a
# -------------------------------
# (c) 2021 suuhm
#
# Troubleshoot failsafemode: https://openwrt.org/docs/guide-user/troubleshooting/failsafe_and_factory_reset#failsafe_mode
# Extroot source: https://openwrt.org/docs/guide-user/additional-software/extroot_configuration
#
#
# EXTROOT OWRT SCRIPT
# No Warranty for anything, please read the articles above first to understand the process!
#

function _set_xedroot() {
        #start checks and opkg update / installs
        echo;echo "[*] Install dependencies:"
        opkg update
        opkg install block-mount kmod-fs-ext4 kmod-usb-storage kmod-usb-ohci kmod-usb-uhci e2fsprogs fdisk

        if [ $? -ne 0 ]; then
                logger -t quick-extroot-owrt.sh "ERROR! Something with opkg went wrong, exit."
                echo;echo "[!!] ERROR! Something with opkg went wrong, exit."
                exit 1;
        fi

        if ! $(ls /dev/ | grep -q sda);
        then
                logger -t quick-extroot-owrt.sh "ERROR! No Device found Script will now exit."
                echo;echo "[!!] ERROR! No Device found Script will now exit."
                exit 1;
        fi

        echo;echo "[*] Set up ExtRoot on your openwrt Device:"
        sleep 3

        # config rootfs_data
        echo;echo "[*] Configure /etc/config/fstab to mount the rootfs_data in another directory"

        MT_DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
        uci -q delete fstab.rwm
        uci set fstab.rwm="mount"
        uci set fstab.rwm.device="${MT_DEVICE}"
        uci set fstab.rwm.target="/rwm"
        uci commit fstab

        # manual: grep -e rootfs_data /proc/mtd
        sleep 3

        if [ ! $1 ]; then
                #Setup dev usb/ssd/etc
                echo;echo "[*] Check for your wished device:"
                sleep 3
                echo "--------------------- LIST OF EXT-DEVICES ---------------------"
                fdisk -l | grep -e '^Disk.*sd' | awk '{print "DEVICENAME: " $2 }'
                echo "---------------------------------------------------------------"
                #lsusb
                echo
                echo "Please enter your Device without Number at the end: (eg. /dev/sda)"
                echo -n "Enter devicename ($__DEV): "; read CH_DEV
                #CH_DEV="/dev/${CH_DEV}"
                if [ -z $CH_DEV ]; then
                        CH_DEV=$__DEV
                elif [ ! -f CH_DEV ]; then
                        echo "Exit now, please enter a devicename WRONGNAME(${CH_DEV})"
                        exit 1;
                else
                        CH_DEV=${CH_DEV}
                fi

                echo "Warning! All Data on ($CH_DEV) will be destroyed! Continue? (y/n)"
                read yn

                if [ "$yn" != "y" ] && [ ! -z $yn ]; then
                        echo;echo "Exit now, pls check your Device first for sense data"
                        exit 0;
                fi
        else
                _check_device $1
                CH_DEV=$__DEV
        fi


                fdisk -l | grep -e ${CH_DEV}1
                
                if [ $? -ne 0 ]; then
                       echo;echo "[*] Create and format device: ($CH_DEV)"
                       fdisk ${CH_DEV} <<EOF
n
p
1


Y
w
EOF
                fi

        echo "--------------------- LIST OF DEVICES ---------------------"
        block info | grep -e sd | awk '{print "USB Devicename: " $1 " ---- UUID: " $2}'
        echo "-----------------------------------------------------------"
        #set kernel invoke:
        #partx /dev/sda

        #set first part. on disk
        XTDEVICE="${CH_DEV}1"
        mkfs.ext4 ${XTDEVICE}

        # configure the selected partition as new overlay via fstab UCI subsystem:

        eval $(block info ${XTDEVICE} | grep -o -e "UUID=\S*")
        uci -q delete fstab.overlay
        uci set fstab.overlay="mount"
        uci set fstab.overlay.uuid="${UUID}"
        uci set fstab.overlay.target="/overlay"
        uci commit fstab

        # Now transfering of current root to new on usb:
        mkdir -p /tmp/cproot
        mount --bind /overlay /tmp/cproot
        mount ${XTDEVICE} /mnt
        tar -C /tmp/cproot -cvf - . | tar -C /mnt -xf -
        umount /tmp/cproot /mnt

        if [ $? -ne 0 ]; then
                logger -t quick-extroot-owrt.sh "ERROR! Something went wrong, exit."
                echo;echo "[!!] ERROR! Something went wrong, exit."
                exit 1;
        fi

        sleep 3
        #reboot
        logger -t quick-extroot-owrt.sh "Done $(date)"
        echo
        echo;echo "****************************************"
        echo "Done. You can now reboot your Device"
        echo "***************************************"
}


# SAVE OPKG LIST TO EXTROOT INSTEAD OF RAM
function _set_opkg2er() {
        sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf
        opkg update
}


# Set up swap on root / not partition
function _set_swap() {
        #Check if device or dd file for swap:
        if [ ! $1 ]; then
                #NULL MBR
                #dd bs=512 count=1 if=/dev/zero of=/dev/sda

                #Calc new SWAP size:
                FS=`free -m | grep -i Mem | awk '{print $2}'`
                NS=$(($FS/1024*4))
                echo;echo "[*] Calculated actually size -> $(($FS/1024)) MB to new size -> $NS MB"
                echo

                dd bs=1M count=$NS if=/dev/zero of=/usr/lib/extroot.swap
                mkswap /usr/lib/extroot.swap

                echo;echo "[*] Enable swap file on /usr/lib/extroot.swap"
                uci -q delete fstab.swap
                uci set fstab.swap="swap"
                uci set fstab.swap.device="/usr/lib/extroot.swap"
                uci commit fstab
                /etc/init.d/fstab boot

        else

                #TODO: shringing of device and setup swap partition in fs:
                _check_device $1
                mkswap $__DEV

                echo;echo "[*] Enable swap file on $1"
                uci -q delete fstab.swap
                uci set fstab.swap="swap"
                uci set fstab.swap.device="$1"
                uci commit fstab
                /etc/init.d/fstab boot
        fi

        echo
        echo;echo "[*] Swap Successful created and activated!"
        echo;echo "[*] Verify swap status"
        cat /proc/swaps
}


function _check_device() {
        if [ "$1" -a $(expr match "$1" '.*sd.*$') -gt 0 ]; then
                echo; echo "[*] device: $1 setup"
                __DEV=$1
        elif [ "$1" -a $(expr match "$1" '.*sd.*$') -eq 0 ]; then
                echo;echo "[!!] ERROR! Device ($1) not found or not correct set, exit"
                exit 1
        fi
}


function _checkfix_extroot() {
        #start checks and opkg update / installs
        echo;echo "[*] Install dependencies:"
        opkg update
        opkg install block-mount kmod-fs-ext4 kmod-usb-storage kmod-usb-ohci kmod-usb-uhci e2fsprogs fdisk

        if [ $? -ne 0 ]; then
                logger -t quick-extroot-owrt.sh "ERROR! Something with opkg went wrong, exit."
                echo "Something went wrong exit now"
                exit 1;
        fi

        if ! $(ls /dev/ | grep -q sda);
        then
                logger -t quick-extroot-owrt.sh "ERROR! No Device found Script will now exit."
                echo;echo "[!!] ERROR! No Device found Script will now exit."
                exit 1;
        fi

        echo;echo "[*] Set up ExtRoot on your openwrt Device:"
        sleep 3

        # config rootfs_data
        echo;echo "[*] Configure /etc/config/fstab to mount the rootfs_data in another directory"

        MT_DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
        uci -q delete fstab.rwm
        uci set fstab.rwm="mount"
        uci set fstab.rwm.device="${MT_DEVICE}"
        uci set fstab.rwm.target="/rwm"
        uci commit fstab

        # manual: grep -e rootfs_data /proc/mtd
        sleep 3

        if [ ! $1 ]; then
                #Setup dev usb/ssd/etc
                echo;echo "[*] Check for your wished device:"
                sleep 3
                echo "--------------------- LIST OF EXT-DEVICES ---------------------"
                fdisk -l | grep -e '^Disk.*sd' | awk '{print "DEVICENAME: " $2 }'
                echo "---------------------------------------------------------------"
                #lsusb
                echo
                echo "Please enter your Device without Number at the end: (eg. /dev/sda)"
                echo -n "Enter devicename ($__DEV): "; read CH_DEV
                #CH_DEV="/dev/${CH_DEV}"
                if [ -z $CH_DEV ]; then
                        CH_DEV=$__DEV
                elif [ ! -f CH_DEV ]; then
                        echo "Exit now, please enter a devicename WRONGNAME(${CH_DEV})"
                        exit 1;
                else
                        CH_DEV=${CH_DEV}
                fi

                echo "Warning! All Data on ($CH_DEV) will be destroyed! Continue? (y/n)"
                read yn

                if [ "$yn" != "y" ] && [ ! -z $yn ]; then
                        echo;echo "Exit now, pls check your Device first for sense data"
                        exit 0;
                fi
        else
                _check_device $1
                CH_DEV=$__DEV
        fi


        echo "--------------------- LIST OF DEVICES ---------------------"
        block info | grep -e sd | awk '{print "USB Devicename: " $1 " ---- UUID: " $2}'
        echo "-----------------------------------------------------------"
        #set kernel invoke:
        #partx /dev/sda

        #set first part. on disk
        XTDEVICE="${CH_DEV}1"

        echo;echo "[*] Mount and delete some extroot-files"
        mount $XTDEVICE /mnt && rm -f /mnt/etc/.extroot-uuid; rm -f /mnt/.extroot-uuid

        # configure the selected partition as new overlay via fstab UCI subsystem:
        eval $(block info ${XTDEVICE} | grep -o -e "UUID=\S*")
        uci -q delete fstab.overlay
        uci set fstab.overlay="mount"
        uci set fstab.overlay.uuid="${UUID}"
        uci set fstab.overlay.target="/overlay"
        uci commit fstab

        if [ $? -ne 0 ]; then
                logger -t quick-extroot-owrt.sh "ERROR! Something went wrong, exit."
                echo;echo "[!!] ERROR! Something went wrong, exit."
                exit 1;
        fi
        
        sleep 3
        #reboot
        logger -t quick-extroot-owrt.sh "Done $(date)"
        echo
        echo;echo "*****************************************"
        echo "Done. You can now reboot your Device"
        echo "*****************************************"
}


# MAIN()
echo "_________________________________________________"
echo "                                                 "
echo "- QICK - EXTROOT OPENWRT v0.2a (c) 2021 - suuhm -"
echo "_________________________________________________"
echo

__DEV="/dev/sda"

if [ "$1" == "--create-extroot" ]; then
        _set_xedroot $2
        exit 0
elif [ "$1" == "--create-swap" ]; then
        _set_swap $2
        exit 0
elif [ "$1" == "--set-opkg2er" ]; then
        _set_opkg2er
        exit 0
elif [ "$1" == "--fixup-extroot" ]; then
        _checkfix_extroot $2
        exit 0
else
        echo;echo "Wrong input! Please enter one of these options:"
        echo
        echo "Usage: $0 <OPTIONS> [DEV]"
        echo
        echo "                  --create-extroot <dev>"
        echo "                  --create-swap <dev>"
        echo "                  --set-opkg2er"
        echo "                  --fixup-extroot <dev>"
        echo
        exit 1;
fi
exit 0
