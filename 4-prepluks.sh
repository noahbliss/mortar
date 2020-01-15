MORTAR_FILE="/etc/mortar/mortar.env"
source "$MORTAR_FILE"
echo "Testing if secure boot is on and working."
od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf
echo "Wiping any existing metadata in the luks keyslot."

luksmeta wipe -d "$CRYPTDEV" -s "$SLOT" #Wipe metadata from keyslot if present. 
echo "Wiping any old luks key in the keyslot. (You'll need to enter a password.)"
cryptsetup luksKillSlot "$CRYPTDEV" "$SLOT"
echo "Generating clevis key, adding it to the luks slot, and mapping it to the TPM PCRs."
clevis-luks-bind -d "$CRYPTDEV" -s "$SLOT" tpm2 '{""pcr_bank":"sha256","pcr_ids":"'"$BINDPCR"'"}'
echo "Adding new sha256 of the luks header to the mortar env file."
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"
HEADERSHA256=$(sha256sum "$HEADERFILE" | cut -f1 -d' ')
sed -i -e "/HEADERSHA256=/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!ba' -e '}' "$MORTAR_FILE"
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
# Get slot uuid and write to MORTAR_FILE. 
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


# REMOVE FROM THIS STEP:
# sed -i "s/HEADERSHA256=.*/HEADERSHA256=$HEADERSHA256/" /etc/initcpio/hooks/clevis
