#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x5000000;   \
 setenv loadaddr 0x1000000;  \
 setenv vloadaddr 0x3000000; \
 setenv dtboaddr 0x4000000;  \

#define PLATFORM_HANDLE_FDT() \
 adtimg get dt --id=\$main_fdt_id dtb_start dtb_size main_fdt_index && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                              \
 fdt addr \$dtbaddr &&                                                 \

#define BOOTLOADER_PARTITION_OVERRIDE() \
 EXTENV(partitions, ";name=bootloader,start=512,size=2096640,uuid=\${uuid_gpt_bootloader}")
