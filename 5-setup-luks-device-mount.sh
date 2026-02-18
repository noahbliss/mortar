#!/usr/bin/env bash
# Noah Bliss
# Set up crypttab, fstab, and mount for a LUKS device.
# This is intended to be run after 4-register-additional-luks-device.sh

# Variables
NEW_CRYPTDEV=$1
NEW_CRYPTNAME=$2
MOUNT_POINT=${3:-"/mnt/$NEW_CRYPTNAME"}
FSTYPE=${4:-"ext4"}
CRYPTTAB_FILE="/etc/crypttab"
FSTAB_FILE="/etc/fstab"

# Check if the device and name are provided
if [ -z "$NEW_CRYPTDEV" ] || [ -z "$NEW_CRYPTNAME" ]; then
    echo "Usage: $0 <device> <name> [mountpoint] [fstype]"
    echo "  device     - Block device path (e.g. /dev/sda1)"
    echo "  name       - LUKS mapping name (e.g. sda1_crypt)"
    echo "  mountpoint - Mount point (default: /mnt/<name>)"
    echo "  fstype     - Filesystem type (default: ext4)"
    exit 1
fi

# Get the UUID of the device
UUID=$(blkid -s UUID -o value "$NEW_CRYPTDEV")
if [ -z "$UUID" ]; then
    echo "Error: Unable to find UUID for $NEW_CRYPTDEV"
    exit 1
fi
CRYPTDEV_UUID="UUID=$UUID"

# Check if the device is already in crypttab
if grep -q "$CRYPTDEV_UUID" "$CRYPTTAB_FILE" 2>/dev/null; then
    echo "$CRYPTDEV_UUID is already registered in $CRYPTTAB_FILE"
else
    echo "$NEW_CRYPTNAME $CRYPTDEV_UUID none luks" >> "$CRYPTTAB_FILE"
    echo "Registered $CRYPTDEV_UUID as $NEW_CRYPTNAME in $CRYPTTAB_FILE"
fi

# Remove existing fstab entries for this crypt name to avoid duplicates
sed -i "\|/dev/mapper/$NEW_CRYPTNAME |d" "$FSTAB_FILE"

# Create mount point and add to fstab
mkdir -p "$MOUNT_POINT"
echo "/dev/mapper/$NEW_CRYPTNAME $MOUNT_POINT $FSTYPE defaults 0 2" >> "$FSTAB_FILE"
echo "Added $NEW_CRYPTNAME to $FSTAB_FILE (type: $FSTYPE, mount: $MOUNT_POINT)"

# Open the LUKS device
cryptsetup luksOpen "$NEW_CRYPTDEV" "$NEW_CRYPTNAME"
if [ $? -ne 0 ]; then
    echo "Error: Failed to open LUKS device $NEW_CRYPTDEV"
    exit 1
fi

# Mount the device
mount "/dev/mapper/$NEW_CRYPTNAME" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount $NEW_CRYPTNAME at $MOUNT_POINT"
    exit 1
fi
echo "Mounted $NEW_CRYPTNAME at $MOUNT_POINT"
