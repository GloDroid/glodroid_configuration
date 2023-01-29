CBC_LOCAL_PATH := $(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

include $(CBC_LOCAL_PATH)/base/board.mk

include $(CBC_LOCAL_PATH)/other-hals/board.mk

ifeq ($(GD_NO_DEFAULT_BLUETOOTH),)
include $(CBC_LOCAL_PATH)/bluetooth/board.mk
endif

ifeq ($(GD_NO_DEFAULT_GRAPHICS),)
include $(CBC_LOCAL_PATH)/graphics/board.mk
endif

ifeq ($(GD_NO_DEFAULT_CODECS),)
include $(CBC_LOCAL_PATH)/codecs/board.mk
endif

ifeq ($(GD_NO_DEFAULT_CAMERA),)
include $(CBC_LOCAL_PATH)/camera/board.mk
endif

ifeq ($(GD_NO_DEFAULT_MODEM),)
include $(CBC_LOCAL_PATH)/modem/board.mk
endif

ifeq ($(GD_NO_DEFAULT_AUDIO),)
include $(CBC_LOCAL_PATH)/audio/board.mk
endif

ifeq ($(GD_NO_DEFAULT_WIFI),)
include $(CBC_LOCAL_PATH)/wifi/board.mk
endif
