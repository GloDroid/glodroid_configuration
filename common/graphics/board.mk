# SPDX-License-Identifier: Apache-2.0
#
# GloDroid project (https://github.com/GloDroid)
#
# Copyright (C) 2022 Roman Stratiienko (r.stratiienko@gmail.com)

BCG_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# AOSPEXT configuration
BOARD_BUILD_AOSPEXT_MESA3D := true
BOARD_MESA3D_SRC_DIR := glodroid/vendor/mesa3d
BOARD_MESA3D_GALLIUM_DRIVERS := lima
BOARD_MESA3D_BUILD_LIBGBM := true

ifeq ($(GD_USE_RS_HWCOMPOSER),)
BOARD_BUILD_AOSPEXT_DRMHWCOMPOSER := true
BOARD_DRMHWCOMPOSER_SRC_DIR := glodroid/vendor/drm_hwcomposer
else
BOARD_BUILD_AOSPEXT_RSHWCOMPOSER := true
BOARD_RSHWCOMPOSER_SRC_DIR := glodroid/vendor/rs-hwcomposer
endif

BOARD_BUILD_AOSPEXT_MINIGBM := true
BOARD_MINIGBM_SRC_DIR := glodroid/vendor/minigbm
BOARD_MINIGBM_PATCHES_DIRS += $(BCG_PATH)/patches-minigbm

BOARD_VENDOR_SEPOLICY_DIRS       += $(BCG_PATH)/sepolicy/vendor
