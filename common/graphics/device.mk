# SPDX-License-Identifier: Apache-2.0
#
# GloDroid project (https://github.com/GloDroid)
#
# Copyright (C) 2022 Roman Stratiienko (r.stratiienko@gmail.com)

# OpenGL driver
PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    libglapi \

PRODUCT_VENDOR_PROPERTIES += ro.hardware.egl=mesa

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml

ifeq ($(GD_USE_RS_HWCOMPOSER),)
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.drm_aospext

    DEVICE_MANIFEST_FILE += glodroid/configuration/common/graphics/android.hardware.graphics.composer@3.xml
    PRODUCT_COPY_FILES += glodroid/configuration/common/graphics/android.hardware.graphics.composer@3.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.graphics.composer@3.rc
else
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.rs \
    android.hardware.composer.hwc3-rs.rc android.hardware.composer.hwc3-rs.xml
endif

## Minigbm/Gralloc5
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm_gd \
    android.hardware.graphics.allocator_gd.rc \
    android.hardware.graphics.allocator_gd.xml \
    android.hardware.graphics.mapper@4.0-impl.minigbm_gd \
    mapper.minigbm_gd \
    mapper.minigbm_gd.xml \
    libminigbm_gralloc_gd \
    libgbm_mesa_wrapper \
    dri_gbm \

##

GD_LCD_DENSITY ?= 160
PRODUCT_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=$(GD_LCD_DENSITY) \
