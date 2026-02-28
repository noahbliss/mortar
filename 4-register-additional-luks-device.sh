#!/usr/bin/env bash
# Noah Bliss

# Variables
NEW_CRYPTDEV=$1
NEW_CRYPTNAME=$2
MORTAR_DIR="/etc/mortar"
MORTAR_FILE="$MORTAR_DIR/mortar-$NEW_CRYPTNAME.env"
INITIAL_MORTAR_FILE="$MORTAR_DIR/mortar.env"

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
rm -f "/etc/mortar/$NEW_CRYPTNAME.header"

# Get slot uuid if LUKS version is 1
if [ "$NEW_LUKSVER" == "1" ]; then
    NEW_SLOTUUID=$(luksmeta show -d "$NEW_CRYPTDEV" -s "$INITIAL_SLOT")
    echo "SLOTUUID=$NEW_SLOTUUID" >> "$MORTAR_FILE"
fi

echo "Created $MORTAR_FILE with necessary environment variables."
