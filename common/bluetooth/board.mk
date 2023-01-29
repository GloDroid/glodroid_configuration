# SPDX-License-Identifier: Apache-2.0

# Some framework code requires this to enable BT

BCB_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

BOARD_HAVE_BLUETOOTH := true
DEVICE_MANIFEST_FILE += $(BCB_PATH)/android.hardware.bluetooth@1.1.xml
