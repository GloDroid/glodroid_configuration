#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x5fa00000;  \

#define PLATFORM_HANDLE_FDT() \
 adtimg get dt --id=\$main_fdt_id dtb_start dtb_size main_fdt_index && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                              \
 fdt addr \$dtbaddr &&                                                 \
