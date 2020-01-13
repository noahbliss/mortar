#!/usr/bin/env bash
# We should sign and use our new EFI file before we require signatures. Better to be safe right?
#THIS FILE IS NOT DONE
source /etc/mortar/mortar.env
echo "Testing for files."

objcopy \
    --add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
    --add-section .cmdline=$(BUILDDIR)/cmdline.txt --change-section-vma .cmdline=0x30000 \
    --add-section .linux=$(KERNEL) --change-section-vma .linux=0x40000 \
    --add-section .initrd=$(BUILDDIR)/initramfs.img --change-section-vma .initrd=0x3000000 \
    $(EFISTUB) $(BUILDDIR)/combined-boot.efi

# Sign the new file. 
sbsign --key ${SBKEYS}/db.key --cert ${SBKEYS}/db.crt --output /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
