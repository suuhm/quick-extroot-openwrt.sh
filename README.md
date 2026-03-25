[![Join Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/2tRn7GWTRm)
[![Stars](https://img.shields.io/github/stars/suuhm/quick-extroot-openwrt.sh?color=gold&style=for-the-badge&logo=github)](https://github.com/suuhm/quick-extroot-openwrt.sh)
[![Forks](https://img.shields.io/github/forks/suuhm/quick-extroot-openwrt.sh?color=silver&style=for-the-badge&logo=github)](https://github.com/suuhm/quick-extroot-openwrt.sh/network)
[![Issues](https://img.shields.io/github/issues/suuhm/quick-extroot-openwrt.sh?color=red&style=for-the-badge&logo=github)](https://github.com/suuhm/quick-extroot-openwrt.sh/issues)
[![PRs](https://img.shields.io/github/issues-pr/suuhm/quick-extroot-openwrt.sh?color=orange&style=for-the-badge&logo=github)](https://github.com/suuhm/quick-extroot-openwrt.sh/pulls)

# quick-extroot-openwrt.sh
Easy and fast shell script to create an extroot on your Storage devives to extend the space on your Openwrt devices.

## How to run the script:
1. First put your wished Storage-Device (USB Stick / USB HDD etc.) in the OpenWRT.

2. Now, simply run these two lines on your serial/ssh console: 
```bash
opkg update ; opkg install libustream-mbedtls && \
wget https://raw.githubusercontent.com/suuhm/quick-extroot-openwrt.sh/main/quick-extroot.sh -qO- | \
sh -s -- --create-extroot 
```
3. Finally reboot your device and enjoy extroot.

<hr>

Alternatively you can just clone the project or copy/paste the file to your ssh console

<hr>

### Functions:
- ```--create-extroot <dev>``` Creating the extroot on your Device (Replace <dev> eg. `/dev/sda`)
- ```--create-swap <dev>``` Creating swap device on Device <dev> (Replace <dev> eg. `/dev/sda`)
- ```--set-opkg2er``` Set up opkg package source list to extroot
- ```--fixup-extroot <dev>``` For some cases this may help you to fix up your Extroot

<br>
<hr>

# If you have some questions and ideas write an issue

<hr>
