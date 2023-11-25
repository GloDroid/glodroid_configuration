#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x5fa00000;  \

#define PLATFORM_HANDLE_FDT() \
 abootimg get dtb --index=\$dtb_index dtb_start dtb_size && \
 cp.b \$dtb_start \$dtbaddr \$dtb_size &&                   \
 fdt addr \$dtbaddr &&                                      \
