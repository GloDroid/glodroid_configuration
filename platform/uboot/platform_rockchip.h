#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x1fa00000;   \

#define BOOTLOADER_PARTITION_OVERRIDE() \
 EXTENV(partitions, ";name=bootloader,start=32K,size=131040K,uuid=\${uuid_gpt_bootloader}")

#define POSTPROCESS_FDT() \
 fdt resize 8192                    && \
 fdt rsvmem add 0x8000000 0x8000000 && \
 fdt rsvmem print &&                   \

#define PLATFORM_HANDLE_FDT() \
 abootimg get dtb --index=\$dtb_index dtb_start dtb_size && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                   \
 fdt addr \$dtbaddr &&                                      \
