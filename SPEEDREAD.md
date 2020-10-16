## Short notes:  

### Get what we need. 
`./0-` and install TPM specific packages once done.  

### Make keys, gen signed EFI, test boot. 
`./1-` && `mortar-compilesigninstall /path/to/vmlinuz-kernel-image /path/to/initramfs.img --install-entry`  
`sync && reboot`


### Install keys and test boot.  
EITHER: Enable Secureboot Custom/Audit then run `./2- ` or: 
```
mkdir -p /boot/efi/EFI/mortar-pub
cp /etc/mortar/private/*.crt /boot/efi/EFI/mortar-pub/
cp /etc/mortar/private/*.der /boot/efi/EFI/mortar-pub/
```

And install keys manually. Enforce Secureboot and test.  

### Prep TPM module through BIOS (both or just SHA256) and set BIOS admin password  

### Add new key to TPM, regen EFI, test boot/unlock  
`./3-` && `mortar-compilesigninstall`  
`sync && reboot`  

### If working, remove boot partition risk  
```
umount /boot/efi
mkdir -p /boot2
cp -r /boot/* /boot2
umount /boot
mv /boot2/* /boot
rmdir /boot2
```

`vim /etc/fstab`  
`mount -a`  

`sync && reboot`
