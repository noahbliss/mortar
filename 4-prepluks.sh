source ./linux-bitlocker.env
echo "Testing if secure boot is on and working."
od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf
echo "Wiping any existing metadata in the luks keyslot."
luksmeta wipe -d /dev/nvme0n1p2 -s 1 #Wipe metadata from keyslot if present. 
echo "Wiping any old luks key in the keyslot. (You'll need to enter a password.)"
cryptsetup luksKillSlot /dev/nvme0n1p2 1
echo "Generating clevis key, adding it to the luks slot, and mapping it to the TPM PCRs."
clevis-luks-bind -d /dev/nvme0n1p2 -s 1 tpm2 '{"pcr_bank":"sha256","pcr_ids":"1,7"}'
echo "Adding new sha256 of the luks header to the initramfs validation script."
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"
HEADERSHA256=$(sha256sum "$HEADERFILE" | cut -f1 -d' ')
sed -i "s/HEADERSHA256=.*/HEADERSHA256=$HEADERSHA256/" ./linux-bitlocker.env
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi

# REMOVE FROM THIS STEP:
# sed -i "s/HEADERSHA256=.*/HEADERSHA256=$HEADERSHA256/" /etc/initcpio/hooks/clevis
