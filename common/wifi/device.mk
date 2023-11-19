# Add wifi-related packages
PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond
PRODUCT_VENDOR_PROPERTIES += wifi.interface=wlan0 \
                              wifi.supplicant_scan_interval=15 \

PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
        $(LOCAL_PATH)/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
        $(LOCAL_PATH)/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
        $(LOCAL_PATH)/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.wifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.wifi.rc \
