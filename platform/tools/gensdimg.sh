#!/bin/bash -e
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# GloDroid project (https://github.com/GloDroid)
#
# use PARTED_TOOL=<path-to-parted.py> ./gensdimg.sh -P=<platform> -T=<type> -C=<out_directory>
#
# <platform>: amlogic, rockchip, sunxi, broadcom
# <type>: SD, DEPLOY-SD, DEPLOY-SD-FOR-EMMC
# <out_directory>: output directory, i.e. out/target/product/generic_x86_64

PARTED_TOOL="$(pwd)/${PARTED_TOOL:-./parted.py}"
PLATFORM=
TYPE=SD
SUFFIX=sd
SDIMG=sdcard.img

gen_image() {
    local BASE_ARGS="--disk-image=$SDIMG"

    rm -f $SDIMG

    if [ "$TYPE" = "DEPLOY-SD-FOR-EMMC" ]; then
        SUFFIX=emmc
    fi

    if [ "$PLATFORM" = "amlogic" ]; then
        BASE_ARGS+=" --gpt-offset=2M" # Default LBA1 is occupied by Amlogic bootloader, so we need to move GPT to 2MB offset
        #BASE_ARGS+=" --no-mbr" # Amlogic bootloader-sd.img contains some sort of MBR and must be written to LBA0
        BL_START=512
        BL_SIZE=$(( 1024 * 1024 * 2 - 512 ))
    fi

    if [ "$PLATFORM" = "rockchip" ]; then
        BL_START=32K
        BL_SIZE=$(( 1024 * 1024 * 2 - 32 * 1024 ))
    fi

    if [ "$PLATFORM" = "sunxi" ]; then
        BL_START=128K
        BL_SIZE=$(( 1024 * 1024 * 2 - 128 * 1024 ))
    fi

    if [ "$TYPE" != "SD" ]; then
        ${PARTED_TOOL} create_empty  ${BASE_ARGS} --size=256M
    else
        ${PARTED_TOOL} create_empty  ${BASE_ARGS} --size=4G
    fi

    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=bootloader --start=${BL_START} --size=${BL_SIZE} --img-file=bootloader-$SUFFIX.img
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=uboot-env  --start=3M          --size=512K       --img-file=env.img

    if [ "$PLATFORM" = "broadcom" ]; then
        # Broadcom ROM code will look for a FAT16 partition on MBR (It doesn't support GPT). Therefore, create a hybrid MBR.
        ${PARTED_TOOL} set_as_mbr_partition ${BASE_ARGS} --partition-name=bootloader
    fi

    # Skip remaining for deploy images
    if [ "$TYPE" != "SD" ]; then
        return
    fi

    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=misc                  --size=512K
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=boot_a                --size=64M  --img-file=boot.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=boot_b                --size=64M
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=vendor_boot_a         --size=32M  --img-file=vendor_boot.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=vendor_boot_b         --size=32M
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=dtbo_a                --size=8M   --img-file=boot_dtbo.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=dtbo_b                --size=8M
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=vbmeta_a              --size=512K --img-file=vbmeta.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=vbmeta_b              --size=512K
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=vbmeta_system_a       --size=512K --img-file=vbmeta_system.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=vbmeta_system_b       --size=512K
    ${PARTED_TOOL} add_image     ${BASE_ARGS} --partition-name=super                             --img-file=super.img
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=metadata              --size=16M
    ${PARTED_TOOL} add_partition ${BASE_ARGS} --partition-name=userdata_placeholder
}

for i in "$@"
do
case $i in
    -C=*|--directory=*)
    cd "${i#*=}"
    shift
    ;;
    -T=*|--type=*)
    TYPE="${i#*=}"
    shift
    ;;
    -P=*|--platform=*)
    PLATFORM="${i#*=}"
    shift
    ;;
    *)
    ;;
esac
done

if [[ -n $1 ]]; then
    SDIMG=$1
else
    SDIMG=sdcard.img
fi

# Check if we have PLATFORM defined
if [ -z "$PLATFORM" ]; then
    echo -e "\033[31m\n   ERROR: PLATFORM is not defined\033[0m"
    exit 1
fi

gen_image

echo -e "\033[32m\n   DONE\033[0m"
