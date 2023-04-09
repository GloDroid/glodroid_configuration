# SPDX-License-Identifier: Apache-2.0
#
# GloDroid project (https://github.com/GloDroid)
#
# Copyright (C) 2022 Roman Stratiienko (r.stratiienko@gmail.com)

BCDC_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

BOARD_BUILD_AOSPEXT_DAV1D := true
BOARD_DAV1D_SRC_DIR := glodroid/vendor/dav1d

BOARD_BUILD_AOSPEXT_FFMPEG := true
BOARD_FFMPEG_SRC_DIR := glodroid/vendor/ffmpeg

BOARD_BUILD_AOSPEXT_FFMPEGCODEC2 := true
BOARD_FFMPEGCODEC2_SRC_DIR := glodroid/vendor/ffmpeg_codec2

BOARD_VENDOR_SEPOLICY_DIRS += $(BCDC_PATH)/sepolicy/vendor

DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(BCDC_PATH)/device_framework_compatibility_matrix_ffmpegcodec2.xml \
