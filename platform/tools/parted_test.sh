#!/bin/bash -e

# SPDX-License-Identifier: GPL-3.0-or-later
#
# GloDroid project (https://github.com/GloDroid)
#
# This script is used to test the parted.py command.

TMP_FILE_NATIVE=/tmp/native.img
TMP_FILE_TOOL=/tmp/tool.img
TMP_IMG_FILE=/tmp/img.img

TEST="No test"

abort() {
    echo -e "\n[\033[91mFAILED\033[0m] $TEST ($1)\n"
    rm -f $TMP_FILE_NATIVE $TMP_FILE_TOOL $TMP_IMG_FILE
    exit 1
}

passed() {
    echo -e "\n[\033[92mPASSED\033[0m] $TEST\n"
}

test() {
    TEST="$1"
    echo -e "\n[\033[93mTEST\033[0m] $TEST\n"
}

# ----------------------------------------------------------------------

test "Empty disk image test"

dd if=/dev/zero of=$TMP_FILE_NATIVE bs=1M count=100
# dd if=/dev/zero of=$TMP_FILE_TOOL bs=1M count=100

# Use native tools
sgdisk --zap-all $TMP_FILE_NATIVE
sgdisk -g $TMP_FILE_NATIVE

# Use parted.py
./parted.py create_empty --disk-image=$TMP_FILE_TOOL --size=100M || abort "Failed to create an empty disk image"

# Compare results
# 40 lines may be not identical.
# 16 bits - UUID (main GPT)
# 16 bits - UUID (backup GPT)
# 4 bits - CRC32 (main GPT)
# 4 bits - CRC32 (backup GPT)

S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 40 ] && abort "The disk images are not identical"

passed

# ----------------------------------------------------------------------

test "Single partition test"

# Use native tools
sgdisk --set-alignment=1 --new 1:$(( 1024*1024*10/512 )):$(( (1024*1024*20/512) - 1 )) --change-name=1:"boot" $TMP_FILE_NATIVE

# Use parted.py
./parted.py add_partition --disk-image=$TMP_FILE_TOOL --partition-name=boot --start=10M --size=10M || abort "Failed to add a partition to the disk image"

# Compare results
# 80 lines may be not identical.
# 40 - same as in the previous test (empty disk image)
# 32 - partition table entry GPT UUID (main GPT + backup GPT)
# 8 - CRC32 of the partition table entries (main GPT + backup GPT)
S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 80 ] && abort "The disk images are not identical"

passed

test "Partition without start test"

# Use native tools
sgdisk --set-alignment=1 --new 2::$(( (1024*1024*25/512) - 1 )) --change-name=2:"second" $TMP_FILE_NATIVE

# Use parted.py
./parted.py add_partition --disk-image=$TMP_FILE_TOOL --partition-name=second --size=5M || abort "Failed to add a partition to the disk image"

# Compare results
# 112 lines may be not identical.
# 80 - same as in the previous test (single partition)
# 32 - new partition table entry GPT UUID (main GPT + backup GPT)
S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 112 ] && abort "The disk images are not identical"

passed

# ----------------------------------------------------------------------

test "Partition without size test (fill the rest of the disk)"

# Use native tools
sgdisk --set-alignment=1 --largest-new=3 --change-name=3:"third" $TMP_FILE_NATIVE

# Use parted.py
./parted.py add_partition --disk-image=$TMP_FILE_TOOL --partition-name=third || abort "Failed to add a partition to the disk image"

# Compare results
# 144 lines may be not identical.
# 112 - same as in the previous test (partition without start)
# 32 - new partition table entry GPT UUID (main GPT + backup GPT)

S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 144 ] && abort "The disk images are not identical"

passed

test "Add GPT partition to the MBR (hybrid MBR)"

# Use native tools
gdisk $TMP_FILE_NATIVE <<EOF
r
h
1
n
04
y
n
m
w
y
EOF

# Use parted.py
./parted.py set_as_mbr_partition --disk-image=$TMP_FILE_TOOL --partition-name=boot --part-type=0x4 || abort "Failed to set a partition as MBR partition"

# Compare results
# 144 lines may be not identical. (same as in the previous test)
S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 144 ] && abort "The disk images are not identical"

passed

# ----------------------------------------------------------------------

test "Write an image to the partition"

# Prepare image
dd if=/dev/urandom of=$TMP_IMG_FILE bs=1M count=10

# Use native tools
dd if=$TMP_IMG_FILE of=$TMP_FILE_NATIVE bs=1M seek=10 conv=notrunc

# Use parted.py
./parted.py add_image --disk-image=$TMP_FILE_TOOL --partition-name=boot --img-file=$TMP_IMG_FILE || abort "Failed to add an image to the partition"

# Compare results
# 144 lines may be not identical. (same as in the previous test)
S=$(cmp -l $TMP_FILE_NATIVE $TMP_FILE_TOOL | wc -l)
[ $S -gt 144 ] && abort "The disk images are not identical"

passed

# ----------------------------------------------------------------------

rm -f $TMP_FILE_NATIVE $TMP_FILE_TOOL $TMP_IMG_FILE
