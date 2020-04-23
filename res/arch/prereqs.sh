pacman -Sy binutils \
        efitools \
        util-linux \
        sbsigntools

echo "Installed Arch dependencies."
echo "If you have a TPM 1.2 module you also need to run:"
echo "Don't know the needed packages yet." #echo "pacman -Sy tpm-tools trousers"
echo "If you have a TPM 2 module you also need to run:"
echo "pacman -Sy tpm2-tools clevis"
