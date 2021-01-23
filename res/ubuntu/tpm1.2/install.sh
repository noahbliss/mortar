#!/usr/bin/env bash
# Noah Bliss

# Install the kernel upgrade hook for generation and signing of the efi.
cp -r kernel /etc/

# Install the initramfs script and update hook. 
cp -r initramfs-tools /etc/

# Install DKMS hook for module signing using /etc/mortar/private/db.key and db.crt.der
cp ../../../chain-sign-hook.conf /var/lib/secureboot/dkms/

INITRAMFSSCRIPTFILE='/etc/initramfs-tools/scripts/local-top/mortar'
source /etc/mortar/mortar.env
sed -i -e "/^CRYPTDEV=.*/{s##CRYPTDEV=\"$CRYPTDEV\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^CRYPTNAME=.*/{s//CRYPTNAME=$CRYPTNAME/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^TPMINDEX=.*/{s//TPMINDEX=$TPMINDEX/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERFILE=.*/{s##HEADERFILE=\"$HEADERFILE\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

bash /opt/mortar/setup-dkms.sh
update-initramfs -u

echo "Initramfs updated. You need to run mortar-compilesigninstall [kernelpath] [initramfspath]"
echo "Consult the README for more detail."
