# quick-extroot-openwrt.sh
Easy and fast shell script to create an Openwrt extroot on your USB stick

## How to run the script:
Simply run this one-liner: 
```
opkg update ; opkg install libustream-mbedtls
wget https://raw.githubusercontent.com/suuhm/quick-extroot-openwrt.sh/main/quick-extroot.sh -qO- | sh -s -- --create-extroot 
```
and reboot your device.

#### Functions:
- ```--create-extroot``` Creating the extroot on your Device
- ```--create-swap``` Creating swap device
- ```--set-opkg2er``` Set up opkg list to extroot

<br>
<hr>

# If you have some questions and ideas write an issue

<hr>
