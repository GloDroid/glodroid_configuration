# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Roman Stratiienko (r.stratiienko@gmail.com)

$(call inherit-product, device/glodroid/opi_plus2/device.mk)

# Architecture
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
#TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_VARIANT := generic
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi

TARGET_SUPPORTS_32_BIT_APPS := true
TARGET_SUPPORTS_64_BIT_APPS := false

PRODUCT_BOARD_PLATFORM := sunxi
PRODUCT_NAME := opi_plus2
PRODUCT_DEVICE := opi_plus2
PRODUCT_BRAND := OrangePI
PRODUCT_MODEL := opi_plus2
PRODUCT_MANUFACTURER := xunlong
PRODUCT_HAS_EMMC := true

GD_LOWRAM_CONFIG := true
GD_NO_DEFAULT_BLUETOOTH := true
GD_NO_DEFAULT_MODEM := true

UBOOT_DEFCONFIG := orangepi_plus_defconfig
KERNEL_SRC       := glodroid/kernel/stable
KERNEL_DEFCONFIG := $(KERNEL_SRC)/arch/arm/configs/sunxi_defconfig
KERNEL_FRAGMENTS += \
    device/glodroid/platform/common/sunxi/sunxi-common.config \

KERNEL_DTB_FILE := sun8i-h3-orangepi-plus.dtb
