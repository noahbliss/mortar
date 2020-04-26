#!/usr/bin/env bash
# Noah Bliss

# Install the kernel upgrade hook for generation and signing of the efi.
cp -r kernel /etc/

## EDIT THIS FOR CENTOS:
# Install the initramfs script and update hook. 
cp -r 60mortar /usr/lib/dracut/modules.d/
INITRAMFSSCRIPTFILE='/usr/lib/dracut/modules.d/60mortar/mortar.sh'
if ! [ "$1" == "nosource" ]; then source /etc/mortar/mortar.env; fi
sed -i -e "/^cryptdev=.*/{s##cryptdev=\"$cryptdev\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^cryptname=.*/{s//cryptname=$cryptname/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^slotuuid=.*/{s//slotuuid=$slotuuid/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^slot=.*/{s//slot=$slot/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^headersha256=.*/{s//headersha256=$headersha256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^headerfile=.*/{s##headerfile=\"$headerfile\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^tokenid=.*/{s//tokenid=$tokenid/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

echo "Installed. You'll need to run \`dracut -f\` then generate and sign the efi file."
