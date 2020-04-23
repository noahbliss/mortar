apt-get update
apt-get install \
        binutils \
        efitools \
        uuid-runtime

echo "Installed initial Ubuntu dependencies."
echo "TPM 1.2 packages not yet known."
#echo "If you have a TPM 1.2 module you also need to run:"
#echo "apt-get install tpm-tools trousers"
echo "If you have a TPM 2 module you also need to manually install the following from the Debian stable repo (see README for details):"
echo "clevis clevis-luks clevis-tpm2 tpm2-tools libtss2-esys0 libtss2-udev"
