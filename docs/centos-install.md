# Centos 8.1 Minimal install.  
## Very rough notes as I get it working. Leaving here if anyone gets a curious itch and wants to beat me to it.  
Selected "encrypt my files" and automatic partitioning. Resulted in:  
```
vda1 - 600MB /boot/efi  
vda2 - 1GB - /boot  
vda3 - luks  
-- LVM on luks (rootfs and swap)   
```

`dnf update && dnf install git`  
`git clone mortar`  
`cd mortar`  
`./0-`  
**Add packages I need to add to ./0 here!**  
`dnf install binutils`  
TPM2  
`dnf install tpm2-tools clevis-luks clevis-dracut`  
Packages that would have gotten automatically added on Debian, but we need to fetch manually here:  
`dnf install mtools`  
CENTOS MIRRORS ARE MISSING PACKAGES WE NEED.  
Get sbsigntools (0.9.3-1.1 worked) and efitools (1.9.2-2.2 worked) from:  
(this is not a sketch link, the dev that uploaded these files has contributions in the git repo of the debian packages too)  
http://download.opensuse.org/repositories/home:/jejb1:/UEFI/Fedora_27/x86_64/  
`rpm -i sbsigntools.rpm`  
`rpm -i efitools.rpm`  
`./1- (works)` (efi keys have been generated/converted/placed in /etc/mortar/private)  
`mortar-compilesigninstall /boot/vmlinuz-{kernelversion} /boot/initramfs-{kernelversion}.img` (looks like centos and debian use a similar directory structure)  

We now have a merged, signed, and bootable efi file.  

Reboot and ensure the efi file works.  

Install secureboot keys with ./2  

Reboot and make sure it still works.  

Lock down the BIOS.  

Once things are as they should be secureboot wise, run ./3 and seal a new LUKS key to the PCRs.  

Reboot and pray.  

Clevis Dracut seems to work just fine from here, give the system a few seconds and it will skip the luks unlock screen and go right to the standard user login prompt.  


We now have a system that auto unlocks. We still need to at least get some kernel upgrade hooks so that the signed efi file is updated when the kernel gets an upgrade.  

Unencrypted boot partition contents confirmed no longer needed at this stage. Take actions included in the main README to reduce risk.  

Ongoing but almost there!  
