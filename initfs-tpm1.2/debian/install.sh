#!/usr/bin/env bash
# Noah Bliss
cp -r initramfs-tools /etc/
source /etc/mortar/mortar.env
INITRAMFSSCRIPTFILE='/etc/initramfs-tools/scripts/local-top/mortar'

sed -i -e "/^CRYPTDEV=.*/{s##CRYPTDEV=\"$CRYPTDEV\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^CRYPTNAME=.*/{s//CRYPTNAME=$CRYPTNAME/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^TPMINDEX=.*/{s//TPMINDEX=$TPMINDEX/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

echo "Installed. You'll need to run \`update-initramfs -u\` then generate and sign the efi file."
