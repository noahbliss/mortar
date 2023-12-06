# Full Disk Encryption and Boot Stack Protection - Mortar + Proxmox

## Warning:  
New versions of Proxmox, specifically the kernel over 5.15 have an issue which breaks compatibility with Mortar. You can use the vanilla Debian kernel instead, however, you will need to ensure it remains the default through upgrades. You may also experience loss of functionality vs. the Proxmox kernel. We have reported this issue on the Proxmox Forums and unfortunately have not gotten any traction.  

## Prerequisites:
 - TPM Module (2.0 preferred, 1.2 also supported)
 - Secureboot-capable host
 - Internet connection

## Goal and Design:

1. Encrypt everything we can including hypervisor OS disk and VM data disks.
2. Automatically unlock disks and restart VMs in event of a hypervisor reboot.
3. Do NOT automatically unlock disks and protect the key if the system has been tampered with. Achieved by storing the key in the TPM module and binding it to relevant PCRs.

For this walk-through I'll be using a VM simulating a common Proxmox install environment:

20GB Proxmox OS disk. (Commonly a pair of disks configured in RAID 1)  
30GB Proxmox Data disk. (Commonly an array of disks configured in RAID 5 or RAID 6 as one virtual disk)  

## Step 1: Install Debian

Overview:  
Boot using UEFI. Install Debian using standard options. At the "Partition Disks" step, select "Guided Use entire disk and set up encrypted LVM." Also be sure to select "All files in one partition."  

Detailed steps:    
I am using the Debian 10.3.0 netinstall ISO. It is critical that you enable and use UEFI boot during installation.  

Configure hostname, domain, root/user account credentials, etc to your needs.  

At the "Partition Disks" step, select "Guided Use entire disk and set up encrypted LVM."  

Select the disk that will home your Proxmox OS.  

Select "All files in one partition."  

Confirm the selection and allow the installer to write random bits if you'd like.  

For "Encryption Passphrase" set a strong password. This will be used as your fallback password in event of automatic unlock failure.  

Accept the default partition structure, finish partitioning, and select "Yes" to commit changes to disk.  

Select "No" for additional disks, and accept the defaults for the mirror repository.  

After installing a few packages, it will ask if you want to participate in the "popularity contest." No is selected by default, both options are fine.  

Under software selection, uncheck all options (using SPACE) except for the bottom 2 ("SSH server" and "standard system utilities").  

When prompted, reboot the system. Remove the ISO/disk and adjust boot options to target the disk where Debian was installed.  

On boot you will be asked for your disk encryption password, enter it to complete the boot process then login as root.  

## Step 2: Begin Mortar installation.  

Overview:  
Install prerequisites. Download Mortar from git. Configure secureboot. Add new key to LUKS, store in TPM module, and bind to secureboot and BIOS config PCRs. Install Mortar boot and update hooks.  

Detailed steps:  


Ensure you have a working internet connection, then run system updates.  
`apt update && apt upgrade -y`  

**If you installed a new kernel as part of the system upgrade, reboot before continuing!**

Install git and download the Mortar repository.  
```
apt install git -y
mkdir git
cd git
git clone https://github.com/noahbliss/mortar
cd mortar
```

Once in the mortar directory, run the `0-` script to install the prerequisite packages.  
`./0-initialsetup-prereqinstall.sh`

If the script warns about "quiet" being detected, it is highly recommended that you remove it from your cmdline.conf file. Simply remove "quiet" from the line.  
`nano /etc/mortar/cmdline.conf`

Before: [picture]  
After: [picture]  

You will then need to install additional dependencies based on your TPM version. If you don't know, refer to your hardware documentation. It is more likely to have a TPM 2.0 module.  

For TPM 1.2:  
`apt install tpm-tools trousers`  

For TPM 2.0:  
`apt install tpm2-tools clevis-tpm2 clevis-luks`  

If this has completed successfully, continue to running script `1-`  
`./1-generatesecurebootkeys.sh`  

This command will have generated secureboot keys and placed them inside `/etc/mortar/private`  

We will need to create and test our boot file **before** enforcing these keys. To do this we'll use `mortar-compilesigninstall`  

This command requires some arguments which will be kernel-version specific, so let's find out what we need.  

```
cd /boot
ls -l
uname -a
```

Please use this screenshot as reference when finding your options: [Picture]  

The `uname -a` command shows us information about the currently-running kernel. In my case I am running 4.19.0-11, which also appears to be the latest version installed in my boot directory, so I will use that. **If the output of uname -a does not match the latest version in boot, you probably performed system upgrades without rebooting. Reboot before performing this step!**  

The command will use the following template format:  
`mortar-compilesigninstall /path/to/vmlinuz-kernel-image /path/to/initramfs.img --install-entry`  

For my specific case, this will be:  
`mortar-compilesigninstall /boot/vmlinuz-4.19.0-11-amd64 /boot/initrd.img-4.19.0-11-amd64 --install-entry`  

As you can see from this result, the new file `/boot/efi/EFI/mortarsecureboot-linux.efi` was created and set as the default boot option for the system. Your specific hardware may _not_ set the newly-made efi as the boot option automatically. If this is the case, set it using your BIOS.  

We will now reboot to see if the system still behaves. Notice during the boot process that there is no grub menu or boot delay anymore. This is because we've completely removed grub from the boot process.  
`sync && reboot`  

If the system boots correctly, you may continue, if not, revert to grub from your boot menu selection and retry the previous steps.  
`cd ~/git/mortar`  

Next we will install and enforce the secureboot keys. This step can vary based on your motherboard manufacturer, but the following steps in order (easiest to hardest) should work for most cases. Once the keys are installed successfully, reboot, enter your BIOS, and ensure that the "mortar" keys are installed and that secureboot is enforcing.     

### Install keys from inside Debian:  

First let's try the automatic secureboot key install:  
`./2-installsecurebootkeys.sh`  

If this works, skip to the secureboot BIOS check, otherwise let's keep going.  

If you get an error relating to "filesystem permissions" or the BIOS isn't configured in audit mode like the below, reboot to your BIOS and check your secureboot settings. Typically you will need to enable secureboot, set the secureboot mode to "Custom", and enable "Audit" or "Enrollment" mode. After enabling these, retry `./2-installsecurebootkeys.sh`  

**RAID CARD WARNING**  
After this command works, reboot to your BIOS and enroll any hashes for devices you need. On Dell servers there is an option to export hash values for the RAID controller and other devices. Enroll these through your secureboot options before rebooting or your system may not boot.  

### Install keys through the BIOS:  

First, from Debian, copy the **public** secureboot keys to the ESP partition. (Easy storage location usually readable by the BIOS for key enrollment)  
```
mkdir -p /boot/efi/EFI/mortar-pub
cp /etc/mortar/private/*.crt /boot/efi/EFI/mortar-pub/
cp /etc/mortar/private/*.der /boot/efi/EFI/mortar-pub/
sync
```

Reboot into the BIOS.  
Enter the secureboot settings, where possible change "Standard Mode" to "Custom Mode" since we will be using our own keys.  

Find the location under Custom settings to enroll your PK. Most BIOS firmwares will require the keys be in DER format so try those first.  

Enroll the PK, KEK, and DB. Additionally

Save, ensure that Secureboot will be attempted.  

**RAID CARD WARNING**  
At this point you will need to manually enroll any hashes for devices you need. On Dell servers there is an option to export hash values for the RAID controller and other devices. Enroll these through your secureboot options before rebooting or your system may not boot.  

If the system boots, go into the Mortar directory, then run `3-`. This will show some information before prompting you to continue. **DO NOT CONTINUE, PRESS CTRL+C to cancel. Either script will work.**  

```
cd ~/git/mortar
./3-tpm2clevis-prepluksandinstallhooks.sh
```

If Secureboot is on and working, you should get output like:   
```
Testing if secure boot is on and working.
   6   0   0   0   1
ENTER to continue only if the last number is a "1" and you are sure the TPM registers are as you want them.
```

Press CTRL+C to cancel this script. If the last number is `0` then you need to troubleshoot why your BIOS isn't enforcing secureboot.  

## Step 3: Set BIOS Password and prep TPM module.  

Reboot to your BIOS and set an "admin" password. We want to require this password be entered before making any new changes to BIOS settings, but not to be required for every reboot.  

[Picture]  

Before exiting the BIOS, also check if there are configurable TPM options:  
If TPM is disabled, enable it.  
If there is an option to clear TPM keys or mark it as "ownable", do it.  
If possible, specify using TPM version 2 over 1.2.  
If possible, specify using **both** SHA1 and SHA256 hashes for PCR registers. If you cannot use both, select only SHA256.  

Once finished, save the BIOS settings and reboot **twice**. This will ensure the secureboot TPM measurement stabilizes.  

## Step 4: Generate new LUKS key, bind it to TPM and Secureboot.  

We are nearing the end, finally we will check that the PCR values from the TPM module are being correctly generated.  
The following command may not work on your version of TPM tools, please search for the correct command if this does not work:  
`tpm2_pcrlist`  

It is critical that both PCR 1 and 7 register a complex value. If they are all 0 or f, you may have an issue with your TPM module and will need to troubleshoot.  

If these PCR values are populated, we can continue with script 3.  

Script 3 is dependent on the version of TPM module that you have. For TPM 2 run:  
`./3-tpm2clevis-prepluksandinstallhooks.sh`
For TPM 1.2 run:  
`./3-tpm1.2-prepluksandinstallhooks.sh`

Follow the prompts.  
[Picture]  

After running, it will tell you that you need to run mortar-compilesigninstall again, do so **without specifying any options**.  
`mortar-compilesigninstall`  

At this point you are done with the Mortar install! Run sync and reboot. Your disk should automatically unlock. If it doesn't try rerunning script 3. If it fails again, review both TPM and Secureboot settings.  
```
sync
reboot
```

[Picture]  

## Step 5. Cleanup and hardening.  

Remove automount of boot partition. **Do not perform this step until the system is booting correctly with Mortar.**  

Copy /boot contents to the main encrypted partition:  
```
umount /boot/efi
mkdir -p /boot2
cp -r /boot/* /boot2
```

Remove or comment out the /boot mount in /etc/fstab  

Find the line:  
`grep ' /boot ' /etc/fstab`  

Comment it out (add a # to the beginning)  
`nano /etc/fstab`  
[Picture]  

Save and exit with: CTRL+X, Y, ENTER  

Unmount /boot and move the files to the directory.   
```
umount /boot
mv /boot2/* /boot
rmdir /boot2
```

Refresh the mounts and make sure everything is as it should be.  
```
mount -a
mount | grep /boot
```

There should only be **one** result, for `/boot/efi` **not** for `/boot`  

[Picture]  


(Optional) Remove Secureboot public keys from EFI partition.  
`rm -rf /boot/efi/EFI/mortar-pub`  

Once done, `sync` and `reboot` to make sure nothing broke.  

## Step 6. Initialize and protect the data disk.  

This step can be performed however you see fit, but for this example we'll be using gocryptfs to do file-based encryption of our data disk.  
However you configure this disk, ensure that the encryption key is stored on the already encrypted Proxmox OS disk on a location viewable only by the root user.  

Install the prerequisites:  
`apt install gdisk fuse gocryptfs`  

Fuse will prompt the initramfs to regenerate, we need to refresh the mortar ef in this case.  
`mortar-compilesigninstall`

Use `cgdisk` to create a new partition on the empty disk. (Select New, then just press enter through all the defaults)  

Select "Write" from the menu to write changes to disk, then exit.  

We now need to format the new partition and ensure it is mounted automatically:  
```
mkfs.ext4 /dev/vdb1
mkdir -p /mnt/data
uuid=$(ls -l /dev/disk/by-uuid/ | grep vdb1 | cut -d' ' -f9)
echo $uuid #make sure we have it.
echo "UUID=$uuid /mnt/data    ext4    errors=remount-ro 0 1" >> /etc/fstab
mount -a
mount #make sure it is in the list!
```
If `mount -a` throws an error, edit /etc/fstab manually.  

Create the directory for our gocryptfs keys and set permissions.  
`mkdir -p /etc/gocryptfs/private`

Next we generate our key.  
`strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 512 | tr -d '\n' > /etc/gocryptfs/private/data.key`

Set secure permissions:  
`chmod go-rwx -R /etc/gocryptfs`  

Create our target directories, and initialize gocryptfs configs.  
```
mkdir /mnt/data/{cryptsrc,cryptmnt}
cd /mnt/data/
cat /etc/gocryptfs/private/data.key | gocryptfs -init -q -config=/etc/gocryptfs/private/data.conf -- cryptsrc
```

Now we just need to add our setup to the fstab and mount the volume!
```
echo "/mnt/data/cryptsrc /mnt/data/cryptmnt fuse./usr/bin/gocryptfs nodev,nosuid,allow_other,quiet,passfile=/etc/gocryptfs/private/data.key,config=/etc/gocryptfs/private/data.conf 0 0">>/etc/fstab
mount -a
mount #make sure it is there!
```

At this point you should be ready to go! After gocryptfs mounts, any data placed inside `/mnt/data/cryptmnt` will be automatically encrypted using file-based encryption.  

**NOTE: Any data placed on the disk OUTSIDE of that specific path will NOT be encrypted.**

## Step 7. Convert Debian to Proxmox.  
https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm

## Step 8. Configure data disk with Proxmox.  
