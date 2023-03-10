# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Roman Stratiienko (r.stratiienko@gmail.com)

$(call inherit-product, device/glodroid/pinetab/device.mk)

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a15

PRODUCT_BOARD_PLATFORM := sunxi
PRODUCT_NAME := pinetab
PRODUCT_DEVICE := pinetab
PRODUCT_BRAND := Pine64
PRODUCT_MODEL := pinetab
PRODUCT_MANUFACTURER := pine64
PRODUCT_HAS_EMMC := true

UBOOT_DEFCONFIG := sopine_baseboard_defconfig
ATF_PLAT        := sun50i_a64

CRUST_FIRMWARE_DEFCONFIG := pinetab_defconfig

KERNEL_SRC       := glodroid/kernel/megous
KERNEL_DEFCONFIG := $(KERNEL_SRC)/arch/arm64/configs/pinephone_defconfig
KERNEL_FRAGMENTS := \
    device/glodroid/platform/common/sunxi/a64_overlay.config \
    device/glodroid/pinetab/kernel.config

KERNEL_DTB_FILE := allwinner/sun50i-a64-pinetab.dtb
