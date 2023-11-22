#pragma once

#define PLATFORM_SETUP_ENV() \
 setenv dtbaddr 0x1fa00000;   \

/* raspberrypi vc bootloader prepare fdt based on many factors. Use this fdt instead of dtb compiled by the kernel */
#define PLATFORM_HANDLE_FDT() \
 fdt addr \${fdt_addr} &&     \
