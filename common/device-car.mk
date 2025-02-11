
#
# All components inherited here go to system image
#
$(call inherit-product, packages/services/Car/car_product/build/car_generic_system.mk)

#
# All components inherited here go to system_ext image
#
$(call inherit-product, packages/services/Car/car_product/build/car_system_ext.mk)

#
# All components inherited here go to product image
#
$(call inherit-product, packages/services/Car/car_product/build/car_product.mk)

#
# All components inherited here go to vendor image
#
$(call inherit-product, packages/services/Car/car_product/build/car_vendor.mk)

PRODUCT_PACKAGES += \
    android.hardware.automotive.vehicle@V3-default-service   \
    android.hardware.automotive.audiocontrol-service.example \

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/car_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/car_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml \
    frameworks/native/data/etc/android.software.activities_on_secondary_displays.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.activities_on_secondary_displays.xml \

# Broadcast Radio
PRODUCT_PACKAGES += android.hardware.broadcastradio-service.default

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.broadcastradio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.broadcastradio.xml \
