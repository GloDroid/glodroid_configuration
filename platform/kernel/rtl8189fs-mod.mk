
MODULES_DIR := $(TARGET_OUT_VENDOR_DLKM)/lib/modules
MODULE := $(PRODUCT_OUT)/obj/RTL8189FTV-MOD/8189fs.ko
MOD_SRC := glodroid/kernel-modules/rtl8189fs
MOD_SRC_FILES := $(sort $(shell find -L $(MOD_SRC) -not -path '*/\.git/*'))

$(MODULE): $(MOD_SRC) $(KERNEL_OUT)/.config $(MOD_SRC_FILES) $(PRODUCT_OUT)/kernel
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp -r $</* $(dir $@)
	$(MAKE_COMMON) $(MAKE_COMMON_CLANG) KSRC=$(AOSP_TOP_ABS)/$(KERNEL_OUT) -C $(dir $@)

#-------------------------------------------------------------------------------
include $(CLEAR_VARS)

LOCAL_MODULE := 8189fs.ko

LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_PATH := $(MODULES_DIR)
LOCAL_PREBUILT_MODULE_FILE := $(MODULE)

include $(BUILD_EXECUTABLE)

#-------------------------------------------------------------------------------
