dnf update
dnf install \
        binutils \
        efitools \
	openssl

echo "Installed Fedora dependencies."
echo "If you have a TPM 1.2 module you also need to run:"
echo "dnf install tpm-tools trousers"
echo "If you have a TPM 2 module you also need to run:"
echo "dnf install tpm2-tools clevis-pin-tpm2 clevis-luks clevis-dracut"
