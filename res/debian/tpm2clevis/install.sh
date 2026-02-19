#!/usr/bin/env bash
# Noah Bliss

# Install the kernel upgrade hook for generation and signing of the efi.
cp -r kernel /etc/

# Install the initramfs script and update hook.
cp -r initramfs-tools /etc/

MORTAR_DIR="/etc/mortar"
MORTAR_FILES=("$MORTAR_DIR"/mortar*.env)
INITRAMFS_DIR="/etc/initramfs-tools/scripts/local-top"
INITIAL_MORTAR_FILE="$INITRAMFS_DIR/mortar"

# Remove previous mortar-* scripts (additional device scripts) from local-top, leaving all other files intact.
find "$INITRAMFS_DIR" -maxdepth 1 -type f -name 'mortar-*' -exec rm -f {} +

for MORTAR_FILE in "${MORTAR_FILES[@]}"; do
    # Clear variables from any previous iteration to prevent leakage.
    unset CRYPTDEV CRYPTNAME SLOTUUID SLOT HEADERSHA256 HEADERFILE TOKENID LUKSVER
    echo "Installing with MORTAR_FILE: $MORTAR_FILE"
    source "$MORTAR_FILE"

    INITRAMFSSCRIPTFILE="$INITRAMFS_DIR/$(basename "$MORTAR_FILE" .env)"
    echo "Create $INITRAMFSSCRIPTFILE ..."
    cp "$INITIAL_MORTAR_FILE" "$INITRAMFSSCRIPTFILE"


    sed -i -e "/^CRYPTDEV=.*/{s##CRYPTDEV=\"$CRYPTDEV\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^CRYPTNAME=.*/{s//CRYPTNAME=$CRYPTNAME/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^SLOTUUID=.*/{s//SLOTUUID=$SLOTUUID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^HEADERFILE=.*/{s##HEADERFILE=\"$HEADERFILE\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
    sed -i -e "/^TOKENID=.*/{s//TOKENID=$TOKENID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
done

update-initramfs -u

echo "Initramfs updated. You need to run mortar-compilesigninstall [kernelpath] [initramfspath]"
echo "Consult the README for more detail."
