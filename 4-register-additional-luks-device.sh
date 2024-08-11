#!/usr/bin/env bash
# Noah Bliss

# Variables
NEW_CRYPTDEV=$1
NEW_CRYPTNAME=$2
MORTAR_DIR="/etc/mortar"
MORTAR_FILE="$MORTAR_DIR/mortar-$NEW_CRYPTNAME.env"
CRYPTTAB_FILE="/etc/crypttab"
FSTAB_FILE="/etc/fstab"
INITIAL_MORTAR_FILE="$MORTAR_DIR/mortar.env"
MOUNT_POINT="/mnt/$NEW_CRYPTNAME"

# Check if the device and name are provided
if [ -z "$NEW_CRYPTDEV" ] || [ -z "$NEW_CRYPTNAME" ]; then
    echo "Usage: $0 <device> <name>"
    exit 1
fi

# Get the UUID of the device
UUID=$(blkid -s UUID -o value "$NEW_CRYPTDEV")
if [ -z "$UUID" ]; then
    echo "Error: Unable to find UUID for $NEW_CRYPTDEV"
    exit 1
fi
NEW_CRYPTDEV="UUID=$UUID"

# Check if the device is already in crypttab
if grep -q "$NEW_CRYPTDEV" "$CRYPTTAB_FILE"; then
    echo "$NEW_CRYPTDEV is already registered in $CRYPTTAB_FILE"
    exit 0
fi

# Register the hard disk in crypttab
echo "$NEW_CRYPTNAME $NEW_CRYPTDEV none luks" >> "$CRYPTTAB_FILE"
echo "Registered $NEW_CRYPTDEV as $NEW_CRYPTNAME in $CRYPTTAB_FILE"

# Source the initial mortar env file and store values in temporary variables
source "$INITIAL_MORTAR_FILE"
INITIAL_SLOT=$SLOT
INITIAL_TOKENID=$TOKENID
INITIAL_TPMHASHTYPE=$TPMHASHTYPE
INITIAL_BINDPCR=$BINDPCR

# Create the new mortar env file
cat <<EOL > "$MORTAR_FILE"
# Environment variables for $NEW_CRYPTNAME
CRYPTDEV="/dev/disk/by-uuid/$UUID"
CRYPTNAME="$NEW_CRYPTNAME"
SLOT=$INITIAL_SLOT
TOKENID=$INITIAL_TOKENID
TPMHASHTYPE="$INITIAL_TPMHASHTYPE"
BINDPCR="$INITIAL_BINDPCR"
HEADERFILE="./$NEW_CRYPTNAME.header"
EOL

# Determine LUKS version of NEW_CRYPTDEV
if cryptsetup isLuks --type luks1 "$NEW_CRYPTDEV"; then 
    NEW_LUKSVER=1
elif cryptsetup isLuks --type luks2 "$NEW_CRYPTDEV"; then
    NEW_LUKSVER=2
else
    echo "Error: $NEW_CRYPTDEV is not a valid LUKS device."
    exit 1
fi
echo "LUKSVER=$NEW_LUKSVER" >> "$MORTAR_FILE"

# Backup LUKS header and calculate SHA256
cryptsetup luksHeaderBackup "$NEW_CRYPTDEV" --header-backup-file "/etc/mortar/$NEW_CRYPTNAME.header"
NEW_HEADERSHA256=$(sha256sum "/etc/mortar/$NEW_CRYPTNAME.header" | cut -f1 -d' ')
echo "HEADERSHA256=$NEW_HEADERSHA256" >> "$MORTAR_FILE"

# Get slot uuid if LUKS version is 1
if [ "$NEW_LUKSVER" == "1" ]; then
    NEW_SLOTUUID=$(luksmeta show -d "$NEW_CRYPTDEV" -s "$INITIAL_SLOT")
    echo "SLOTUUID=$NEW_SLOTUUID" >> "$MORTAR_FILE"
fi

echo "Created $MORTAR_FILE with necessary environment variables."

# Remove existing mounts for the disk in fstab
sed -i "\|$NEW_CRYPTNAME|d" "$FSTAB_FILE"

# Create mount point and add to fstab
mkdir -p "$MOUNT_POINT"
echo "/dev/mapper/$NEW_CRYPTNAME $MOUNT_POINT ext4 defaults 0 2" >> "$FSTAB_FILE"
echo "Added $NEW_CRYPTNAME to $FSTAB_FILE"

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
