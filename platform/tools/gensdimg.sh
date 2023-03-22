#!/bin/bash -e

PLATFORM=sunxi

# Old Allwinner boot ROM looks for the SPL binary starting from 16th LBA of SDCARD and EMMC.
# Newer Alwinner SOCs including H3, A64, and later is looking for SPL at both 16th LBA and 256th LBA.
# Align first partition to 256th LBA to allow update bootloader binaries using fastboot.
PART_START=$(( 256 * 512 ))

# 1 MiB alignment is relevant for USB flash devices. Follow that rules to improve
# read performance when using SDCARD with USB card reader.
ALIGN=$(( 2048 * 512 ))

PTR=$PART_START
pn=1

add_part() {
	echo -e "\033[95m===> Adding partition $1, image $2, size=$3, offset=$PTR\033[0m"

	SIZE=$3
	if [ -z "$SIZE" ]; then
	    SIZE=$(stat $2 -c%s)
	fi

	SGCMD="--new $pn:$(( PTR / 512 )):$(( ($PTR + $SIZE - 1) / 512 ))"

	sgdisk --set-alignment=1 $SGCMD --change-name=$pn:"$1" ${SDIMG}

	dd if=$2 of=$SDIMG bs=4k count=$(( SIZE / 4096 )) seek=$(( $PTR / 4096 )) conv=notrunc && sync

	PTR=$(( ($PTR + $SIZE + $ALIGN - 1) / $ALIGN * $ALIGN ))
	pn=$(( $pn + 1 ))
}

add_empty_part() {
	SIZE=$2
	echo -e "\033[95m===> Adding empty partition $1: size=$SIZE, offset=$PTR\033[0m"

	if [ "$SIZE" != "-" ]; then
	    SGCMD="--new $pn:$(( PTR / 512 )):$(( ($PTR + $SIZE - 1) / 512 ))"
	else
	    SGCMD="--largest-new=$pn"
	fi

	sgdisk --set-alignment=1 $SGCMD --change-name=$pn:"$1" ${SDIMG}

	PTR=$(( ($PTR + $SIZE + $ALIGN - 1) / $ALIGN * $ALIGN ))
	pn=$(( $pn + 1 ))
}

prepare_disk() {
    if [ -e "$SDIMG" ]; then
        SDSIZE=$(stat $SDIMG -c%s)
    else
        SDSIZE=$(( 1024 * 1024 * $1 ))
        echo "===> Create raw disk image"
        dd if=/dev/zero of=$SDIMG bs=4096 count=$(( $SDSIZE / 4096 ))
    fi;

    echo "===> Clean existing partition table"
    sgdisk --zap-all $SDIMG
}

modify_for_rpi() {
    echo "===> Transforming GPT to hybrid partition table"
    gdisk $SDIMG <<EOF
r
h
1
n
04
y
n
m
w
y
EOF
}

gen_sd() {
    prepare_disk $(( 1024 * 8 )) # Default size - 8 GB

    echo "===> Add partitions"
    add_part       bootloader      bootloader-sd.img
    add_part       uboot-env       env.img
    add_empty_part misc                                  $(( 512 * 1024 ))
    add_part       boot_a          boot.img        $(( 64 * 1024 * 1024 ))
    add_empty_part boot_b                          $(( 64 * 1024 * 1024 ))
    add_part       vendor_boot_a   vendor_boot.img $(( 32 * 1024 * 1024 ))
    add_empty_part vendor_boot_b                   $(( 32 * 1024 * 1024 ))
    add_part       dtbo_a          boot_dtbo.img    $(( 8 * 1024 * 1024 ))
    add_empty_part dtbo_b                           $(( 8 * 1024 * 1024 ))
    add_part       vbmeta_a        vbmeta.img            $(( 512 * 1024 ))
    add_empty_part vbmeta_b                              $(( 512 * 1024 ))
    add_part       vbmeta_system_a vbmeta_system.img     $(( 512 * 1024 ))
    add_empty_part vbmeta_system_b                       $(( 512 * 1024 ))
    add_part       super           super.img
    add_empty_part metadata                        $(( 16 * 1024 * 1024 ))
    add_empty_part userdata -

    if [ "$PLATFORM" = "broadcom" ]; then
        modify_for_rpi
    fi
}

gen_deploy() {
    local SUFFIX=$1
    prepare_disk $(( 256 )) # Default size - 256 MB

    echo "===> Add partitions"
    if [ "$PLATFORM" = "rockchip" ] && [ "$SUFFIX" == "emmc" ]; then
        add_part bootloader bootloader-deploy-emmc.img
    else
        add_part bootloader bootloader-$SUFFIX.img
    fi
    add_part uboot-env env.img
    add_part recovery_boot boot.img

    if [ "$PLATFORM" = "broadcom" ]; then
        modify_for_rpi
    fi
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

if [ "$PLATFORM" = "rockchip" ]; then
    PART_START=$(( 64 * 512 ))
    PTR=$PART_START
fi

if [[ -n $1 ]]; then
    SDIMG=$1
else
    SDIMG=sdcard.img
fi

case $TYPE in
    DEPLOY-SD)
    gen_deploy "sd"
    ;;
    DEPLOY-SD-FOR-EMMC)
    gen_deploy "emmc"
    ;;
    SD|*)
    gen_sd
    ;;
esac

echo -e "\033[32m\n   DONE\033[0m"
