# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Roman Stratiienko (r.stratiienko@gmail.com)

$(call inherit-product, device/glodroid/common/device-common.mk)

# Firmware
PRODUCT_COPY_FILES += \
    glodroid/kernel-firmware/megous/rtl_bt/rtl8723cs_xx_fw.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/rtl_bt/rtl8723cs_xx_fw.bin \
    glodroid/kernel-firmware/megous/rtl_bt/rtl8723cs_xx_config.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/rtl_bt/rtl8723cs_xx_config.bin \
    glodroid/kernel-firmware/megous/anx7688-fw.bin:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/anx7688-fw.bin \
    glodroid/kernel-firmware/megous/regulatory.db:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/regulatory.db \
    glodroid/kernel-firmware/megous/regulatory.db.p7s:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/regulatory.db.p7s \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sensors.pinephone.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/sensors.pinephone.rc \
    $(LOCAL_PATH)/typec.pinephone.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/typec.pinephone.rc \
    $(LOCAL_PATH)/modem.pinephone.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/modem.pinephone.rc \
    $(LOCAL_PATH)/power.pinephone.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/power.pinephone.rc \

PRODUCT_COPY_FILES += \
    device/glodroid/pinephone/audio.pinephone.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio.pinephone.xml \

# Lights HAL
PRODUCT_PACKAGES += \
    android.hardware.lights-service.pinephone \

# Vibrator HAL
PRODUCT_PACKAGES += \
    android.hardware.vibrator-service.pinephone \

PRODUCT_PACKAGES += \
    sensors.iio \
    android.hardware.sensors@1.0-impl:64 \
    android.hardware.sensors@1.0-service

# Checked by android.opengl.cts.OpenGlEsVersionTest#testOpenGlEsVersion. Required to run correct set of dEQP tests.
# 131072 == 0x00020000 == GLES v2.0
PRODUCT_VENDOR_PROPERTIES += \
    ro.opengles.version=131072

# RRO that disables round items in quicksetting menu to increase performance
PRODUCT_PACKAGES += \
    SystemUISlowGpu
