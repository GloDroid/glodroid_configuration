#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x5000000;   \

#define PLATFORM_HANDLE_FDT() \
 abootimg get dtb --index=\$dtb_index dtb_start dtb_size && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                   \
 fdt addr \$dtbaddr &&                                      \

#define BOOTLOADER_PARTITION_OVERRIDE() \
 EXTENV(partitions, ";name=bootloader,start=512,size=2096640,uuid=\${uuid_gpt_bootloader}")
