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
Packages that would have gotten automatically added on Debian, but we need to fetch manually here:  
`dnf install mtools`  
CENTOS MIRRORS ARE MISSING PACKAGES WE NEED.  
Get sbsigntools (0.9.3-1.1 worked) and efitools (1.9.2-2.2 worked) from:  
(this is not a sketch link, the dev that uploaded these files has contributions in the git repo of the debian packages too)  
http://download.opensuse.org/repositories/home:/jejb1:/UEFI/Fedora_27/x86_64/  
`rpm -i sbsigntools.rpm`  
`rpm -i efitools.rpm`  
`./1- (works)` (efi keys have been generated/converted/placed in /etc/mortar/private  
`mortar-compilesigninstall /boot/vmlinuz-{kernelversion} /boot/initramfs-{kernelversion}.img` (looks like centos and debian use a similar directory structure)  

So far this gets us a merged, signed, and bootable efi file. We haven't installed secureboot keys yet and haven't touched TPM.  


Ongoing.  
