# Android makefile to build kernel as a part of Android build

LOCAL_PATH := $(call my-dir)

GLODROID_PROJECT_NAME := KERNEL

ifneq ($(BOARD_BUILD_GLODROID_KERNEL),)

AOSP_ABSOLUTE_PATH := $(realpath .)

KERNEL_FRAGMENTS	:= \
	$(LOCAL_PATH)/android-base.config        \
	$(LOCAL_PATH)/android-recommended.config \
	$(LOCAL_PATH)/android-extra.config       \
	$(KERNEL_FRAGMENTS)

ifeq ($(TARGET_ARCH),arm64)
KERNEL_FRAGMENTS	+= \
	$(LOCAL_PATH)/android-recommended-arm64.config \
	$(LOCAL_PATH)/android-extra-arm64.config
else
KERNEL_FRAGMENTS	+= \
	$(LOCAL_PATH)/android-recommended-arm.config \
	$(LOCAL_PATH)/android-extra-arm.config
endif

KERNEL_OUT		:= $(PRODUCT_OUT)/obj/GLODROID/KERNEL
KERNEL_TARGET		:= $(KERNEL_OUT)/install/kernel
KERNEL_DTB_OUT		:= $(KERNEL_OUT)/install/dtbs

KERNEL_SRC_FILES        := $(sort $(shell find -L $(BOARD_KERNEL_SRC_DIR) -not -path '*/\.git/*'))
KERNEL_PATCHES := $(if $(BOARD_KERNEL_PATCHES_DIRS),$(sort $(shell find -L $(BOARD_KERNEL_PATCHES_DIRS) -not -path '*/\.*')))


$(KERNEL_TARGET): RUST_BIN_DIR_ABS := $(if $(RUST_BIN_DIR),$(shell cd $(RUST_BIN_DIR) && pwd),$(HOME)/.cargo/bin)
$(KERNEL_TARGET): LOCAL_PATH := $(LOCAL_PATH)
$(KERNEL_TARGET): KERNEL_OUT := $(KERNEL_OUT)
$(KERNEL_TARGET): KCONFIG_OUT_FRAGMENTS := $(foreach frag,$(KERNEL_FRAGMENTS),configs/$(notdir $(frag)))
$(KERNEL_TARGET): KERNEL_PATCHES_DIRS := $(BOARD_KERNEL_PATCHES_DIRS)
$(KERNEL_TARGET): $(KERNEL_DEFCONFIG) $(KERNEL_FRAGMENTS) $(KERNEL_SRC_FILES) $(KERNEL_PATCHES)
	mkdir -p $(KERNEL_OUT)
	mkdir -p $(KERNEL_OUT)/configs
	cp $(KERNEL_FRAGMENTS) $(KERNEL_OUT)/configs/
	cp $(KERNEL_DEFCONFIG) $(KERNEL_OUT)/configs/defconfig
	cp $(LOCAL_PATH)/../tools/makefile_base.mk $(KERNEL_OUT)/Makefile
	cp $(LOCAL_PATH)/../tools/makefile_kernel.mk $(KERNEL_OUT)/project_specific.mk
	sed -i \
		-e 's#\[PLACE_FOR_TARGET_ARCH\]#$(TARGET_ARCH)#g' \
		-e 's#\[PLACE_FOR_AOSP_ROOT\]#$(AOSP_ABSOLUTE_PATH)#g' \
		-e 's#\[PLACE_FOR_SRC_DIR\]#$(BOARD_KERNEL_SRC_DIR)#g' \
		-e 's#\[PLACE_FOR_PATCHES_DIRS\]#$(KERNEL_PATCHES_DIRS)#g' \
		-e 's#\[PLACE_FOR_OUT_BASE_DIR\]#$(dir $(MESON_GEN_DIR))#g' \
		$(KERNEL_OUT)/Makefile

	sed -i \
		-e 's#\[PLACE_FOR_KCONFIG_FRAGMENTS\]#$(KCONFIG_OUT_FRAGMENTS)#g' \
		$(KERNEL_OUT)/project_specific.mk

# Disable interposer and use LLVM compiler toolchain from AOSP tree
	export ETC$$(cat /etc/environment) && export PATH=$(AOSP_ABSOLUTE_PATH)/$(LLVM_PREBUILTS_PATH):$(RUST_BIN_DIR_ABS):$$ETCPATH:$$PATH && make -C $(KERNEL_OUT) install

# Post processing:

TARGET_VENDOR_MODULES   := $(TARGET_OUT_VENDOR_DLKM)/lib/modules
ANDROID_DTS_OVERLAY	?= $(LOCAL_PATH)/empty.dts

DTB_OUTPUT		:= $(PRODUCT_OUT)/dtb.img

$(TARGET_VENDOR_MODULES)/modules.dep: $(KERNEL_TARGET)
	rm -rf $(TARGET_VENDOR_MODULES)/kernel
	rm -f $(TARGET_VENDOR_MODULES)/modules.*
	mkdir -p $(TARGET_VENDOR_MODULES)/kernel
	cp -r $(KERNEL_OUT)/install/modules/lib/modules/GloDroid/kernel/* $(TARGET_VENDOR_MODULES)/kernel/
	cp -r $(KERNEL_OUT)/install/modules/lib/modules/GloDroid/modules.* $(TARGET_VENDOR_MODULES)/
	touch $@

$(PRODUCT_OUT)/kernel: $(KERNEL_TARGET) $(TARGET_VENDOR_MODULES)/modules.dep
	cp -v $< $@

$(PRODUCT_OUT)/vendor_dlkm.img: $(TARGET_VENDOR_MODULES)/modules.dep

$(DTB_OUTPUT): $(KERNEL_TARGET)
	echo cat $(foreach dtb,$(KERNEL_DTB_FILE) $(KERNEL_DTB_FILES),$(AOSP_TOP_ABS)/$(KERNEL_DTB_OUT)/$(dtb) ) > $@
	cat $(foreach dtb,$(KERNEL_DTB_FILE) $(KERNEL_DTB_FILES),$(AOSP_TOP_ABS)/$(KERNEL_DTB_OUT)/$(dtb) ) > $@

#-------------------------------------------------------------------------------

include $(LOCAL_PATH)/rtl8189es-mod.mk
include $(LOCAL_PATH)/rtl8189fs-mod.mk

endif # BOARD_BUILD_GLODROID_KERNEL
