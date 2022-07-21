#!/usr/bin/env bash
# Noah Bliss

# Install the kernel upgrade hook for generation and signing of the efi.
cp -r kernel /etc/

# Install the initramfs script and update hook. 
cp -r initramfs-tools /etc/
INITRAMFSSCRIPTFILE='/etc/initramfs-tools/scripts/local-top/mortar'
source /etc/mortar/mortar.env
for CRYPTNAME in $CRYPTNAMES; do CRYPTPAIRS="$CRYPTNAME:$(cryptnametodevice $CRYPTNAME) $CRYPTPAIRS"; done
sed -i -e "/^CRYPTPAIRS=.*/{s//CRYPTPAIRS=\"$CRYPTPAIRS\"/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^TPMINDEX=.*/{s//TPMINDEX=$TPMINDEX/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=\"$HEADERSHA256\"/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERFILE=.*/{s##HEADERFILE=\"$HEADERFILE\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

update-initramfs -u

echo "Initramfs updated. You need to run mortar-compilesigninstall [kernelpath] [initramfspath]"
echo "Consult the README for more detail."
