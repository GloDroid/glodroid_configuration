BCOH_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

BOARD_VENDOR_SEPOLICY_DIRS       += $(BCOH_PATH)/sepolicy/vendor
