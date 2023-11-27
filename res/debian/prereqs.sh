apt-get update
apt-get install \
        binutils \
        efitools \
        systemd-boot-efi \
        uuid-runtime \
        gawk

echo "Installed Debian dependencies."
echo "If you have a TPM 1.2 module you also need to run:"
echo "apt-get install tpm-tools trousers"
echo "If you have a TPM 2 module you also need to run:"
echo "apt-get install tpm2-tools clevis-tpm2 clevis-luks"
