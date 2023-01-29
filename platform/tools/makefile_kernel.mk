#!/usr/bin/make
KCONFIG_FRAGMENTS:=[PLACE_FOR_KCONFIG_FRAGMENTS]

CONFIGURE_TARGET:=./logs/3.configure.log
BUILD_TARGET:=./logs/4.build.log
INSTALL_TARGET:=./logs/5.install.log

NUMPROC := $(shell nproc)

KMAKE:= make -C $(OUT_BUILD_DIR) ARCH=$(TARGET_ARCH) LLVM=y DTC_FLAGS='--symbols'

configure: ## Configure the project
configure: export BASE_DIR = $(OUT_BASE_DIR)
configure: $(CONFIGURE_TARGET)
$(CONFIGURE_TARGET): $(PATCH_TARGET)
	@echo Configuring...
	@mkdir -p $(OUT_BUILD_DIR)
	@make -C $(OUT_SRC_DIR) O=$(OUT_BUILD_DIR) defconfig &> $@.tmp || (cat $@.tmp && exit 1)
	@cp configs/defconfig $(OUT_BUILD_DIR)/.config  &>> $@.tmp || (cat $@.tmp && exit 1)
	@$(KMAKE) olddefconfig &>> $@.tmp || (cat $@.tmp && exit 1)
	@$(OUT_SRC_DIR)/scripts/kconfig/merge_config.sh -m -O $(OUT_BUILD_DIR)/ $(OUT_BUILD_DIR)/.config $(KCONFIG_FRAGMENTS) &>> $@.tmp || (cat $@.tmp && exit 1)
	@$(KMAKE) olddefconfig &>> $@.tmp || (cat $@.tmp && exit 1)
	@mv $@.tmp $@ -f

build: ## Build the project
build: export BASE_DIR = $(OUT_BASE_DIR)
build: $(BUILD_TARGET)
$(BUILD_TARGET): $(CONFIGURE_TARGET)
	@echo Building...
	@mkdir -p $(OUT_BUILD_DIR)
	@$(KMAKE) dtbs all -j$(NUMPROC) &> $@.tmp || (cat $@.tmp && exit 1)
	@mv $@.tmp $@ -f

.ONESHELL:

install: ## Install the project (will execute copy, patch, configure and build prior to install)
install: $(INSTALL_TARGET)
$(INSTALL_TARGET): $(BUILD_TARGET)
	@echo Installing...
	@mkdir -p $(OUT_INSTALL_DIR)
	@export KERNEL_IMAGE=$$($(KMAKE) -s image_name)
	@$(KMAKE) \
		INSTALL_PATH=$(OUT_INSTALL_DIR) INSTALL_MOD_PATH=$(OUT_INSTALL_DIR)/modules INSTALL_DTBS_PATH=$(OUT_INSTALL_DIR)/dtbs \
		install modules_install dtbs_install \
		&> $@.tmp || (cat $@.tmp && exit 1)

	export KERNELRELEASE=$$(cat $(OUT_BUILD_DIR)/include/config/kernel.release)

	@mv $(OUT_INSTALL_DIR)/vmlinuz-$${KERNELRELEASE} $(OUT_INSTALL_DIR)/vmlinuz
	@mv $(OUT_INSTALL_DIR)/config-$${KERNELRELEASE} $(OUT_INSTALL_DIR)/config
	@mv $(OUT_INSTALL_DIR)/System.map-$${KERNELRELEASE} $(OUT_INSTALL_DIR)/System.map

	@rm -rf $(OUT_INSTALL_DIR)/modules/lib/modules/GloDroid
	@mv $(OUT_INSTALL_DIR)/modules/lib/modules/$${KERNELRELEASE} $(OUT_INSTALL_DIR)/modules/lib/modules/GloDroid

ifeq ($(TARGET_ARCH),arm64)
	@lz4c -f -c1 $(OUT_INSTALL_DIR)/vmlinuz $(OUT_INSTALL_DIR)/kernel &>>$@ || (cat $@.tmp && exit 1)
else
	@cp $(OUT_INSTALL_DIR)/vmlinuz $(OUT_INSTALL_DIR)/kernel
endif

	@mv $@.tmp $@ -f
