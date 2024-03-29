#!/bin/sh -xe

# Update bootloader to ensure we have latest GPT table layout.
./fastboot flash gpt deploy-gpt.img
./fastboot flash bootloader bootloader__SUFFIX__.img
./fastboot flash uboot-env  env.img
./fastboot reboot

set +x
if [ "__SUFFIX__" = "-emmc" ]; then
  echo "Power-down, remove recovery SD-CARD, and power-up the board."
  echo "Press enter to continue."
  read key
fi
set -x

# Flash
./fastboot oem format
./fastboot flash bootloader      bootloader__SUFFIX__.img
./fastboot flash uboot-env       env.img
./fastboot flash boot            boot.img
./fastboot flash init_boot       init_boot.img
./fastboot flash vendor_boot     vendor_boot.img
./fastboot flash vbmeta_a        vbmeta.img
./fastboot flash vbmeta_system_a vbmeta_system.img
./fastboot erase misc
./fastboot erase frp

./fastboot reboot-fastboot

./fastboot flash super  super.img

./fastboot -w

./fastboot reboot
