#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x1fa00000;   \
 setenv loadaddr 0x10008000;  \
 setenv vloadaddr 0x13008000; \
 setenv dtboaddr 0x12008000;  \

#define BOOTLOADER_PARTITION_OVERRIDE() \
 EXTENV(partitions, ";name=bootloader,start=32K,size=131040K,uuid=\${uuid_gpt_bootloader}")

#define POSTPROCESS_FDT() \
 fdt rsvmem add 0x8000000 0x8000000 && \
 fdt rsvmem print &&                   \

#define PLATFORM_HANDLE_FDT() \
 adtimg get dt --id=\$main_fdt_id dtb_start dtb_size main_fdt_index && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                              \
 fdt addr \$dtbaddr &&                                                 \
