#!/usr/bin/env bash
# Noah Bliss

# Install the kernel upgrade hook for generation and signing of the efi.
#cp -r kernel /etc/
mkdir -p /usr/local/share/libalpm/hooks
cp -r hooks/mortar.hook /usr/share/libalpm/hooks/

# Install the initramfs script and update hook. 
cp -r initcpio /etc/
INITRAMFSSCRIPTFILE='/etc/initcpio/hooks/mortar'
if ! [ "$1" == "nosource" ]; then source /etc/mortar/mortar.env; fi
sed -i -e "/^CRYPTDEV=.*/{s##CRYPTDEV=\"$CRYPTDEV\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^CRYPTNAME=.*/{s//CRYPTNAME=$CRYPTNAME/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOTUUID=.*/{s//SLOTUUID=$SLOTUUID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERFILE=.*/{s##HEADERFILE=\"$HEADERFILE\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^TOKENID=.*/{s//TOKENID=$TOKENID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

echo "Installed."
echo "Please add \"mortar\" to your /etc/mkinitcpio.conf \"HOOKS=\" immediately prior to the \"encrypt\" hook."
echo "You'll then need to run \`mkinitcpio -P\` then generate and sign the efi file with the \"mortar-compilesigninstall\" command."

