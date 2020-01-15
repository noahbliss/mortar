#!/usr/bin/env bash
MORTAR_FILE="/etc/mortar/mortar.env"
source "$MORTAR_FILE"
echo "Testing if secure boot is on and working."
od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf
if (command -v luksmeta >/dev/null); then
	echo "Wiping any existing metadata in the luks keyslot."
	luksmeta wipe -d "$CRYPTDEV" -s "$SLOT"
fi
echo "Wiping any old luks key in the keyslot. (You'll need to enter a password.)"
cryptsetup luksKillSlot "$CRYPTDEV" "$SLOT"
read -p "If this is the first time running, do you want to attempt taking ownership of the tpm? (y/N): " takeowner
case "$takeowner" in
	[yY]*) tpm_takeownership -z ;;
esac

if (mkdir tmpramfs && mount tmpfs -t tmpfs -o size=1M,noexec,nosuid tmpramfs); then
	echo "Generating key..."
	dd bs=1 count=512 if=/dev/urandom of=tmpramfs/mortar.key
	chmod 700 tmpramfs/mortar.key
	cryptsetup luksAddKey "$CRYPTDEV" --key-slot "$SLOT" 
	rm  tmpramfs/mortar.key
	umount -l tmpramfs
	rmdir tmpramfs
else
	echo "Failed to create tmpramfs for storing the key."
	exit 1
fi

echo "Adding new sha256 of the luks header to the mortar env file."
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"
HEADERSHA256=$(sha256sum "$HEADERFILE" | cut -f1 -d' ')
sed -i -e "/HEADERSHA256=/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!ba' -e '}' "$MORTAR_FILE"
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
