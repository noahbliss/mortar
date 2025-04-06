#!/usr/bin/env bash
# Noah Bliss
OLD_DIR="$PWD"
MORTAR_DIR="/etc/mortar"
MORTAR_FILES=("$MORTAR_DIR"/mortar*.env)

echo "Testing if secure boot is on and working."
od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf

for MORTAR_FILE in "${MORTAR_FILES[@]}"; do
    echo "Processing MORTAR_FILE: $MORTAR_FILE"
    source "$MORTAR_FILE"

    # Determine LUKS version of CRYPTDEV if not told.
    if [ -z "$LUKSVER" ]; then
        if cryptsetup isLuks --type luks1 "$CRYPTDEV"; then 
            LUKSVER=1
        elif cryptsetup isLuks --type luks2 "$CRYPTDEV"; then
            LUKSVER=2
        fi
    fi

    # Remove tpmfs from failed runs if applicable.
    if [ -d tmpramfs ]; then
        echo "Removing existing tmpramfs..."
        umount tmpramfs
        rm -rf tmpramfs
    fi

    # Create tpmramfs for read user luks password to file.
    if mkdir tmpramfs && mount tmpfs -t tmpfs -o size=1M,noexec,nosuid tmpramfs; then
        echo "Created tmpramfs to store luks key during setup."
        trap "if [ -f tmpramfs/user.key ]; then rm -f tmpramfs/user.key; fi" EXIT
        echo -n "Enter luks password to open $CRYPTNAME: "; read -s PASSWORD; echo
        echo -n "$PASSWORD" > tmpramfs/user.key
        unset PASSWORD
    else
        echo "Failed to create tmpramfs for storing the key."
        exit 1
    fi

    # if luks1
    if [ "$LUKSVER" == "1" ]; then
        echo "Wiping any existing metadata in the luks keyslot."
        luksmeta wipe -d "$CRYPTDEV" -s "$SLOT" # Wipe metadata from keyslot if present. 
    fi

    # if luks2
    if [ "$LUKSVER" == "2" ]; then
        echo "Wiping any clevis token from LUKS header."
        cryptsetup token remove --token-id "$TOKENID" "$CRYPTDEV"
    fi

    echo "Wiping any old luks key in the keyslot."
    cryptsetup luksKillSlot --key-file tmpramfs/user.key "$CRYPTDEV" "$SLOT" 
    echo "Generating clevis key, adding it to the luks slot, and mapping it to the TPM PCRs."
    clevis-luks-bind -d "$CRYPTDEV" -k tmpramfs/user.key -s "$SLOT" tpm2 '{"pcr_bank":"'"$TPMHASHTYPE"'","pcr_ids":"'"$BINDPCR"'"}'
    echo "Wiping keys and unmounting tmpramfs."
    rm tmpramfs/user.key
    umount -l tmpramfs
    rm -rf tmpramfs

    echo "Adding new sha256 of the luks header to the mortar env file."
    if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
    cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"
    HEADERSHA256=$(sha256sum "$HEADERFILE" | cut -f1 -d' ')
    sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$MORTAR_FILE"
    if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi

    # Get slot uuid and write to MORTAR_FILE. 
    if [ "$LUKSVER" == "1" ]; then
        CURSLOTUUID=$(luksmeta show -d  "$CRYPTDEV" -s "$SLOT")
        if [ -z "$SLOTUUID" ]; then 
            SLOTUUID="$CURSLOTUUID"
            sed -i -e "/SLOTUUID=/{s//SLOTUUID=$SLOTUUID/;:a" -e '$!N;$!ba' -e '}' "$MORTAR_FILE"
            echo "Updated SLOTUUID in $MORTAR_FILE"
        else
            echo "Looks like SLOTUUID was set in the env file. Verify it is still correct with: luksmeta show -d $CRYPTDEV"
            if [ "$SLOTUUID" == "$CURSLOTUUID" ]; then echo "[ MATCHES ]"; else echo "[ DIFFERS ]"; fi
            echo "ENV file SLOTUUID: $SLOTUUID"
            echo "Current SLOTUUID:  $CURSLOTUUID"
        fi
    fi
done


# Figure out our distribuition.
source /etc/os-release
tpmverdir='tpm2clevis'
# Defer to tpm and distro-specific install script.
if [ -d "$OLD_DIR/""res/""$ID/""$tpmverdir/" ]; then
        cd "$OLD_DIR/""res/""$ID/""$tpmverdir/"
        echo "Distribution: $ID"
        echo "Installing kernel update and initramfs build scripts with mortar*.env values..."
        bash install.sh # Start in new process so we don't get dropped to another directory.
else
        echo "Distribution: $ID"
        echo "Could not find scripts for your distribution."
fi

