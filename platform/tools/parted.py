#!/usr/bin/env python3

# SPDX-License-Identifier: GPL-3.0-or-later
#
# GloDroid project (https://github.com/GloDroid)
#
# CLI: python3 parted.py command [args]
#
# Simple partition editing CLI tool designed to fit the needs of the GloDroid project
#
# args: --gpt-offset=<gpt_offset> (optional for every command, default: 512)
# args: --no-mbr (don't create a protective MBR, optional for every write command, default: False)
# args: --disk-image=<image_file> (mandatory for every command)
# args: --img-file=<image_file>
# args: --start=<start, bytes>
# args: --size=<size, bytes>
# args: --partition-name=<partition_name>
#
# command: init - create an empty disk image (image shall not exist)
#          Valid args: --disk-image=... --size=...
#
# command: add_partition - add an empty partition to a disk image
#          Valid args: --disk-image=... --partition-name=...
#                      [--start=...] [--size=...]
#          Comments: If --start is not specified, the partition will be added to the end of the disk.
#                    If --size is not specified, the remaining disk space will be used.
#
# command: add_image - write an image into a partition (creates new partition if needed)
#          Valid args: --disk-image=... --img-file=... --partition-name=...
#                      [--start=...] [--size=...]
#          Comments: If --start is not specified, the image will be written to the end of the disk.
#                    If --size is not specified, the image size will be used.
#                    If you want to use the remaining disk space, run the add_partition command first, then add_image.
#                    If the partition is already present, --start and --size are ignored.
#
# command: dump - dump the partition table of a disk image
#          Valid args: --disk-image=...
#
# command: set_as_mbr_partition - add a partition to the MBR partition table (creates a hybrid MBR)
#          Valid args: --disk-image=... --partition-name=... --part-type=...

import sys
import struct
import zlib
import os
import uuid

GPT_HEADER_FORMAT = "<8sIIIIQQQQ16sQIII"
GPT_PARTITION_ENTRY_FORMAT = "<16s16sQQQ72s"
LINUX_PART_GUID = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
PART_TYPE_UUIDS = {
    uuid.UUID(LINUX_PART_GUID): "Linux",
}

gpt_offset = 512
no_mbr = False
partition_alignment = 1 * 1024 * 1024 # 1 MiB
gpt_partitions = []

def div_round_up(a, b):
    return (a + b - 1) // b

def update_gpt_headers_crc(disk_image):
    disk_size = os.path.getsize(disk_image)
    with open(disk_image, "r+b") as f:
        f.seek(gpt_offset)
        gpt_header_data = f.read(92)
        signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32 = struct.unpack(GPT_HEADER_FORMAT, gpt_header_data)
        f.seek(gpt_offset + 512)
        part_table = f.read(num_part_entries * part_entry_size)
        part_entry_array_crc32 = zlib.crc32(part_table) & 0xffffffff
        crc32 = 0
        gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
        gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)
        crc32 = zlib.crc32(gpt_header_data) & 0xffffffff
        gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
        gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)
        f.seek(gpt_offset)
        f.write(gpt_header_data)

        current_lba = disk_size // 512 - 1
        backup_lba = div_round_up(gpt_offset, 512)
        part_entry_start_lba = (disk_size - num_part_entries * part_entry_size) // 512 - 1
        crc32 = 0

        gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
        gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)
        crc32 = zlib.crc32(gpt_header_data) & 0xffffffff
        gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
        gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)

        gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
        gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)

        f.seek(disk_size - 512)
        f.write(gpt_header_data)

def read_gpt_table(disk_image):
    gpt_partitions.clear()
    with open(disk_image, "r+b") as f:
        f.seek(gpt_offset + 512)
        gpt_entries_data = f.read(128 * 128)
        for i in range(128):
            gpt_entry_data = gpt_entries_data[i * 128:(i + 1) * 128]
            if gpt_entry_data == b"\0" * 128:
                break

            gpt_entry = struct.unpack(GPT_PARTITION_ENTRY_FORMAT, gpt_entry_data)
            gpt_partitions.append(gpt_entry)

def store_gpt_table(disk_image):
    disk_size = os.path.getsize(disk_image)
    with open(disk_image, "r+b") as f:
        for i in range(len(gpt_partitions)):
            gpt_entry = gpt_partitions[i]
            gpt_entry_data = struct.pack(GPT_PARTITION_ENTRY_FORMAT, *gpt_entry)
            # Write the GPT entry to the disk image
            f.seek(gpt_offset + 512 + i * 128)
            f.write(gpt_entry_data)
            # Write the GPT entry to the end of the disk image
            f.seek(disk_size + i * 128 - 512 * 33)
            f.write(gpt_entry_data)

    update_gpt_headers_crc(disk_image)

def dump_gpt_table():
    for i in range(len(gpt_partitions)):
        gpt_entry = gpt_partitions[i]
        partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, partition_name = gpt_entry
        partition_type_guid = partition_type_guid.hex()
        unique_partition_guid = unique_partition_guid.hex()
        partition_name = partition_name.decode("utf-16le").rstrip("\0")

        if partition_type_guid in PART_TYPE_UUIDS:
            partition_type_guid = PART_TYPE_UUIDS[partition_type_guid]

        print(f"Partition {i}: {partition_name} ({partition_type_guid}); LBA: {starting_lba} - {ending_lba}; UUID: {unique_partition_guid}; Attributes: {attributes}")

def lba_to_chs(lba, sectors_per_track, heads):
    sectors_per_cylinder = sectors_per_track * heads
    cylinder = lba // sectors_per_cylinder
    remainder = lba % sectors_per_cylinder
    head = remainder // sectors_per_track
    sector = (remainder % sectors_per_track) + 1  # Sectors are usually 1-indexed in CHS notation
    if cylinder > 1023:
        # We cannot represent more than 1023 cylinders in CHS notation
        cylinder = 1023
        head = heads
        sector = sectors_per_track

    return struct.pack("BBB", head, ((cylinder >> 8) << 6) | sector, cylinder & 0xff)

def store_protected_mbr(disk_image, hybrid_part_name, hybrid_part_type):
    if no_mbr:
        print("Trying to store a protective MBR, but --no-mbr was specified")
        exit(1)

    gpt_zone_start_lba = 1 # We do not use gpt_offset here, because u-boot is expecting 1 otherwise it will not recognize GPT.
    gpt_zone_end_lba = os.path.getsize(disk_image) // 512 - 1

    # 446 bytes for bootstrap (not used in GPT), we set them to zeroes
    bootstrap = struct.pack('446B', *[0]*446)

    if hybrid_part_name:
        read_gpt_table(disk_image)
        partition_name = None
        for i in range(len(gpt_partitions)):
            gpt_entry = gpt_partitions[i]
            partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, partition_name = gpt_entry
            partition_name = partition_name.decode("utf-16le").rstrip("\0")
            if partition_name == hybrid_part_name:
                gpt_zone_end_lba = starting_lba - 1 # The GPT protective MBR partition ends at the start of the first GPT partition
                break

        if not partition_name:
            print(f"FAIL: Partition {hybrid_part_name} not found in GPT table")
            exit(1)

        lba_start = int(starting_lba)
        chs_start = lba_to_chs(lba_start, 63, 255)
        lba_end = int(ending_lba)
        chs_end = lba_to_chs(lba_end, 63, 255)

        hybrid_part_entry = struct.pack('B3sB3sII', 0x80, chs_start, hybrid_part_type, chs_end, lba_start, lba_end - lba_start + 1)

    lba_start = int(gpt_zone_start_lba)
    chs_start = lba_to_chs(lba_start, 63, 255)
    lba_end = int(gpt_zone_end_lba)
    chs_end = lba_to_chs(lba_end, 63, 255)
    mbr_partition_entry = struct.pack('B3sB3sII', 0x00, chs_start, 0xEE, chs_end, lba_start, lba_end - lba_start + 1)

    # Four partition entries are available in MBR, but GPT uses only one. The other three can be zeroes
    null_partition_entry = struct.pack('16B', *[0]*16)

    if hybrid_part_name:
        partition_entries = hybrid_part_entry + mbr_partition_entry + null_partition_entry * 2
    else:
        partition_entries = mbr_partition_entry + null_partition_entry * 3

    # MBR signature (0x55AA)
    signature = struct.pack('H', 0xAA55)

    # Combine all parts
    mbr = bootstrap + partition_entries + signature

    # Write the MBR to the disk image
    with open(disk_image, "r+b") as f:
        f.seek(0)
        f.write(mbr)

def create_empty_gpt_header_and_table(disk_image):
    disk_size = os.path.getsize(disk_image)

    # Create an empty GPT table
    signature = b"EFI PART"
    revision = 0x00010000
    header_size = 92
    crc32 = 0
    reserved = 0
    current_lba = div_round_up(gpt_offset, 512)
    backup_lba = disk_size // 512 - 1
    disk_guid = uuid.uuid4().bytes_le
    part_entry_start_lba = div_round_up(gpt_offset, 512) + 1
    num_part_entries = 128
    part_entry_size = 128
    part_entry_array_crc32 = 0
    first_usable_lba = div_round_up(gpt_offset + 512 + num_part_entries * part_entry_size, 512)
    last_usable_lba = backup_lba - 33

    gpt_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
    gpt_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_header)

    gpt_backup_header = (signature, revision, header_size, crc32, reserved, current_lba, backup_lba, first_usable_lba, last_usable_lba, disk_guid, part_entry_start_lba, num_part_entries, part_entry_size, part_entry_array_crc32)
    gpt_backup_header_data = struct.pack(GPT_HEADER_FORMAT, *gpt_backup_header)

    # Write the GPT header and table to the disk image
    with open(disk_image, "r+b") as f:
        f.seek(gpt_offset)
        f.write(gpt_header_data)
        # Backup GPT header will be written by update_gpt_headers_crc() function

    store_gpt_table(disk_image)

    if not no_mbr:
        store_protected_mbr(disk_image, None, None)

    update_gpt_headers_crc(disk_image)

    print(f"  Empty GPT header and table written to {disk_image}")

def create_empty_partition(disk_image, partition_name, start, size):
    disk_size = os.path.getsize(disk_image)

    read_gpt_table(disk_image)

    ranges = []

    for partition in gpt_partitions:
        partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, part_name = partition
        ranges.append((starting_lba * 512, ending_lba * 512, part_name))

    if not no_mbr:
        # Add the MBR partition
        ranges.append((0, 512, "MBR"))

    ranges.append((gpt_offset, gpt_offset + 33 * 512, "GPT"))
    ranges.append((disk_size - (33 * 512), disk_size, "Backup GPT"))

    if start < 0 or start + size > disk_size:
        print("FAIL: Partition is out of bounds.")
        sys.exit(1)

    # Check if the new partition overlaps with any existing partition
    for r in ranges:
        if start >= r[0] and start < r[1]:
            print(f"FAIL: Partition start overlaps with an existing segment: {r[2]}")
            sys.exit(1)

        if start + size > r[0] and start + size <= r[1]:
            print(f"FAIL: Partition end overlaps with an existing segment: {r[2]}")
            sys.exit(1)

        if start < r[0] and start + size > r[1]:
            print(f"FAIL: Partition overlaps with an existing segment: {r[2]}")
            sys.exit(1)

    # Create a new partition entry
    partition_type_guid = uuid.UUID(LINUX_PART_GUID).bytes_le
    unique_partition_guid = uuid.uuid4().bytes_le

    starting_lba = div_round_up(start, 512)
    ending_lba = div_round_up(start + size, 512) - 1
    attributes = 0
    part_name = partition_name.encode("utf-16le")
    part_name += b"\x00" * (72 - len(partition_name))

    partition_entry = (partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, part_name)

    gpt_partitions.append(partition_entry)

    store_gpt_table(disk_image)

def get_last_partition_end(disk_image):
    read_gpt_table(disk_image)

    last_partition_end = gpt_offset + 34 * 512

    for partition in gpt_partitions:
        partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, partition_name = partition
        if ending_lba * 512 > last_partition_end:
            last_partition_end = (ending_lba + 1) * 512

    return last_partition_end

def write_img_to_partition(disk_image, partition_name, img_file, start, size):
    disk_size = os.path.getsize(disk_image)

    read_gpt_table(disk_image)

    img_size = os.path.getsize(img_file)

    partition = None

    for p in gpt_partitions:
        if p[5].decode("utf-16le").strip("\x00") == partition_name:
            partition = p
            break

    if partition is None:
        if start == None:
            start = get_last_partition_end(disk_image)

        if size == None:
            size = img_size

        print(f"  Creating empty partition \"{partition_name}\" [start: {start}, size: {size}]")

        create_empty_partition(disk_image, partition_name, start, size)
        partition = gpt_partitions[-1]

    partition_type_guid, unique_partition_guid, starting_lba, ending_lba, attributes, part_name = partition

    part_size = (ending_lba + 1 - starting_lba) * 512
    if img_size > part_size:
        print(f"FAIL: Image file is too big for the partition \"{partition_name}\" ({img_size} > {part_size})")
        sys.exit(1)

    with open(img_file, "rb") as f_in:
        with open(disk_image, "r+b") as f:
            f.seek(starting_lba * 512)
            f.write(f_in.read(img_size))

    print(f"  Image written to the \"{partition_name}\" partition ({img_size} bytes).")

def parse_suffixes(size):
    if size.endswith("K"):
        return int(size[:-1]) * 1024

    if size.endswith("M"):
        return int(size[:-1]) * 1024 * 1024

    if size.endswith("G"):
        return int(size[:-1]) * 1024 * 1024 * 1024

    return int(size)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Invalid number of arguments.")
        sys.exit(1)

    command = sys.argv[1]

    disk_image = None
    partition_name = None
    img_file = None
    start = None
    size = None
    part_type = None

    for arg in sys.argv[2:]:
        if arg.startswith("--disk-image="):
            disk_image = arg.split("=")[1]

        if arg.startswith("--gpt-offset="):
            gpt_offset = parse_suffixes(arg.split("=")[1])

        if arg.startswith("--start="):
            start = parse_suffixes(arg.split("=")[1])

        if arg.startswith("--size="):
            size = parse_suffixes(arg.split("=")[1])

        if arg.startswith("--partition-name="):
            partition_name = arg.split("=")[1]

        if arg.startswith("--img-file="):
            img_file = arg.split("=")[1]

        if arg.startswith("--part-type="): # may be 0x (hex)
            part_type = arg.split("=")[1]
            if part_type.startswith("0x"):
                part_type = int(part_type[2:], 16)

        if arg.startswith("--no-mbr"):
            no_mbr = True

    if command == "dump":
        if disk_image is None:
            print("Missing --disk-image argument.")
            sys.exit(1)

        read_gpt_table(disk_image)
        dump_gpt_table()

        exit(0)

    if command == "create_empty":
        if disk_image is None:
            print("Missing --disk-image argument.")
            sys.exit(1)

        # check if disk image already exists
        if os.path.exists(disk_image):
            print(f"{disk_image} already exists.")
            sys.exit(1)

        if size == None:
            print("Missing --size argument.")
            sys.exit(1)

        # resize disk image (fast)
        with open(disk_image, "wb") as f:
            f.seek(size - 1)
            f.write(b"\0")

        print(f"\nCreating empty disk image \"{disk_image}\" ({size} bytes).")

        create_empty_gpt_header_and_table(disk_image)

        exit(0)

    if command == "add_partition":
        if disk_image is None:
            print("Missing --disk-image argument.")
            sys.exit(1)

        if partition_name is None:
            print("Missing --partition-name argument.")
            sys.exit(1)

        if size == 0:
            print("Missing --size argument.")
            sys.exit(1)

        if start is None:
            start = get_last_partition_end(disk_image)

        if size is None:
            disk_size = os.path.getsize(disk_image)
            size = disk_size - (512 * 33) - start

        print(f"\nCreating partition \"{partition_name}\" [start: {start}, size: {size}]")

        create_empty_partition(disk_image, partition_name, start, size)

        exit(0)

    if command == "add_image":
        if disk_image is None:
            print("Missing --disk-image argument.")
            sys.exit(1)

        if partition_name is None:
            print("Missing --partition-name argument.")
            sys.exit(1)

        if img_file is None:
            print("Missing --img-file argument.")
            sys.exit(1)

        print(f"\nWriting \"{img_file}\" to partition \"{partition_name}\"")

        write_img_to_partition(disk_image, partition_name, img_file, start, size)

        exit(0)

    if command == "set_as_mbr_partition":
        if disk_image is None:
            print("Missing --disk-image argument.")
            sys.exit(1)

        if partition_name is None:
            print("Missing --partition-name argument.")
            sys.exit(1)

        if part_type is None:
            print("Missing --part-type argument.")
            sys.exit(1)

        print(f"\nSetting partition \"{partition_name}\" as MBR partition with type {part_type}.")

        store_protected_mbr(disk_image, partition_name, part_type)

        exit(0)
