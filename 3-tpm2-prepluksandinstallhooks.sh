#!/usr/bin/env bash
# Noah Bliss
set -e
MORTAR_FILE="/etc/mortar/mortar.env"
OLD_DIR="$PWD"
source "$MORTAR_FILE"
echo "Testing if secure boot is on and working."
od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf

# Determine LUKS version of CRYPTDEV if not told.
if [ -z "$LUKSVER" ]; then
	if (cryptsetup isLuks --type luks1 "$CRYPTDEV"); then 
		LUKSVER=1
	elif (cryptsetup isLuks --type luks2 "$CRYPTDEV"); then
		LUKSVER=2
	fi
fi

# if luks1
if [ "$LUKSVER" == "1" ]; then
	echo "Wiping any existing metadata in the luks keyslot."
	luksmeta wipe -d "$CRYPTDEV" -s "$SLOT" #Wipe metadata from keyslot if present. 
fi

# if luks2
if [ "$LUKSVER" == "2" ]; then
	echo "Wiping any clevis token from LUKS header."
	cryptsetup token remove --token-id "$TOKENID" "$CRYPTDEV"
fi

echo "Wiping any old luks key in the keyslot. (You'll need to enter a password.)"
cryptsetup luksKillSlot "$CRYPTDEV" "$SLOT"
echo "Generating clevis key, adding it to the luks slot, and mapping it to the TPM PCRs."
clevis-luks-bind -d "$CRYPTDEV" -s "$SLOT" tpm2 '{"pcr_bank":"'"$TPMHASHTYPE"'","pcr_ids":"'"$BINDPCR"'"}'
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

# Figure out our distribuition.
source /etc/os-release
tpmverdir='tpm2'
# Defer to tpm and distro-specific install script.
if [ -d "$OLD_DIR/""res/""$ID/""$tpmverdir/" ]; then
        cd "$OLD_DIR/""res/""$ID/""$tpmverdir/"
        echo "Distribution: $ID"
        echo "Installing kernel update and initramfs build scripts with mortar.env values..."
        bash install.sh # Start in new process so we don't get dropped to another directory.
else
        echo "Distribution: $ID"
        echo "Could not find scripts for your distribution."
fi

