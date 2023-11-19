# SPDX-License-Identifier: Apache-2.0
#
# GloDroid project (https://github.com/GloDroid)
#
# Copyright (C) 2022 Roman Stratiienko (r.stratiienko@gmail.com)

PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.0-service \

PRODUCT_PACKAGES += \
    android.hardware.media.c2@1.2-service-ffmpeg \
    android.hardware.media.c2@1.2-service-ffmpeg.rc \
    android.hardware.media.c2@1.2-service-ffmpeg.xml \
    media_codecs_ffmpeg_c2.xml \

# Create input surface on the framework side
PRODUCT_VENDOR_PROPERTIES += \
    debug.stagefright.c2inputsurface=-1 \

GD_MEDIACODECS_FILE ?= $(LOCAL_PATH)/media_codecs.xml

# Copy media codecs config file
PRODUCT_COPY_FILES += \
    $(GD_MEDIACODECS_FILE):$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    $(LOCAL_PATH)/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \

# Vendor seccomp policy files:
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy \
    $(LOCAL_PATH)/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \

# Codec2.0 poolMask:
#   ION(16)
#   GRALLOC(17)
#   BUFFERQUEUE(18)
#   BLOB(19)
#   V4L2_BUFFERQUEUE(20)
#   V4L2_BUFFERPOOL(21)
#   SECURE_LINEAR(22)
#   SECURE_GRAPHIC(23)
#
# For linear buffer allocation:
#   If ION is chosen, then the mask should be 0xf50000
#   If GRALLOC is chosen, then the mask should be 0xf60000
#   If BLOB is chosen, then the mask should be 0xfc0000
PRODUCT_VENDOR_PROPERTIES += \
    debug.stagefright.c2-poolmask=0x0c0000 \
