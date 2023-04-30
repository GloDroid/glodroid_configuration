#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x5fa00000;  \
 setenv loadaddr 0x50008000; \
 setenv vloadaddr 0x53008000;\
 setenv dtboaddr 0x52008000; \

#define PLATFORM_HANDLE_FDT() \
 adtimg get dt --id=\$main_fdt_id dtb_start dtb_size main_fdt_index && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                              \
 fdt addr \$dtbaddr &&                                                 \
