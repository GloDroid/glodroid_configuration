GENSDIMG := $(PLATFORM_PATH)/tools/gensdimg.sh
PARTED := $(PLATFORM_PATH)/tools/parted.py

NATIVE_PATH := PATH=/sbin:/bin:/usr/bin:$$PATH

DEPLOY_TOOLS := \
	$(HOST_OUT_EXECUTABLES)/adb \
	$(HOST_OUT_EXECUTABLES)/fastboot \

DEPLOY_BOOTLOADER := \
	$(PRODUCT_OUT)/bootloader-sd.img \
	$(PRODUCT_OUT)/env.img \

ifneq ($(PRODUCT_HAS_EMMC),)
ifeq ($(PRODUCT_BOARD_PLATFORM),rockchip)
DEPLOY_BOOTLOADER += $(PRODUCT_OUT)/bootloader-deploy-emmc.img
endif
DEPLOY_BOOTLOADER += $(PRODUCT_OUT)/bootloader-emmc.img
endif

DEPLOY_FILES := \
	$(DEPLOY_TOOLS) \
	$(DEPLOY_BOOTLOADER) \
	$(PRODUCT_OUT)/flash-sd.sh \
	$(PRODUCT_OUT)/deploy-sd.img \
	$(PRODUCT_OUT)/boot.img \
	$(PRODUCT_OUT)/init_boot.img \
	$(PRODUCT_OUT)/vendor_boot.img \
	$(PRODUCT_OUT)/super.img \
	$(PRODUCT_OUT)/vbmeta.img \
	$(PRODUCT_OUT)/vbmeta_system.img \
	$(PRODUCT_OUT)/deploy-gpt.img \

ifneq ($(PRODUCT_HAS_EMMC),)
DEPLOY_FILES += \
	$(PRODUCT_OUT)/flash-emmc.sh \
	$(PRODUCT_OUT)/deploy-sd-for-emmc.img \

endif

$(PRODUCT_OUT)/flash-sd.sh: $(PLATFORM_PATH)/tools/flash-all.sh
	cp $< $@
	sed -i "s/__SUFFIX__/-sd/g" $@

$(PRODUCT_OUT)/flash-emmc.sh: $(PLATFORM_PATH)/tools/flash-all.sh
	cp $< $@
	sed -i "s/__SUFFIX__/-emmc/g" $@

$(PRODUCT_OUT)/deploy-sd.img: $(GENSDIMG) $(PARTED) $(DEPLOY_BOOTLOADER) $(PRODUCT_OUT)/boot.img
	rm -f $@
	$(NATIVE_PATH) PARTED_TOOL=$(PARTED) $< -C=$(PRODUCT_OUT) -T=DEPLOY-SD -P=$(PRODUCT_BOARD_PLATFORM) $(notdir $@)

$(PRODUCT_OUT)/deploy-sd-for-emmc.img: $(GENSDIMG) $(PARTED) $(DEPLOY_BOOTLOADER) $(PRODUCT_OUT)/boot.img
	rm -f $@
	$(NATIVE_PATH) PARTED_TOOL=$(PARTED) $< -C=$(PRODUCT_OUT) -T=DEPLOY-SD-FOR-EMMC -P=$(PRODUCT_BOARD_PLATFORM) $(notdir $@)

$(PRODUCT_OUT)/deploy-gpt.img: $(PRODUCT_OUT)/deploy-sd.img $(GENSDIMG) $(PARTED)
	dd if=$< of=$@ bs=1k count=128

$(PRODUCT_OUT)/sdcard.img: $(GENSDIMG) $(PARTED) $(DEPLOY_FILES)
	$(call pretty,"Creating sdcard image...")
	rm -f $@
	$(NATIVE_PATH) PARTED_TOOL=$(PARTED) $< -C=$(PRODUCT_OUT) -T=SD -P=$(PRODUCT_BOARD_PLATFORM)

.PHONY: sdcard
sdcard: $(PRODUCT_OUT)/sdcard.img

$(PRODUCT_OUT)/sdcard.img.zip: $(PRODUCT_OUT)/sdcard.img
	zip -u $@ $<

.PHONY: sdcardzip
sdcardzip: $(PRODUCT_OUT)/sdcard.img.zip

$(PRODUCT_OUT)/images.tar.gz: $(DEPLOY_FILES)
	cp $(DEPLOY_TOOLS) $(PRODUCT_OUT)
	tar -C$(PRODUCT_OUT) -czvf $@ $(notdir $^)

.PHONY: images
images: $(PRODUCT_OUT)/images.tar.gz
