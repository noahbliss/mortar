# Mortar  
Framework to join Linux's physical security bricks. 

UNDER HEAVY DEVELOPMENT.  
Debian - LUKS2(and luks1 assumed) + TPM1.2 working.  
Debian - LUKS2 + TPM2 working.

## What is it?  
Mortar is an attempt to take the headache and fragmented processes out of joining Secureboot, TPM keys, and LUKS.  

Through the "Mortar Model" everything on disk that is used is either encrypted, signed, or hashed. The TPM is used to effectively whitelist certain boot states. Disks are automatically unlocked once the boot sequence has been validated. This makes full-disk encryption dramatically more convenient for end-users and viable on servers (as they can automatically unlock on reboot).  
Mortar aims to support both TPM 1.2 (via its own implementation) and TPM 2 (via clevis).

LUKS1 and LUKS2 are both supported by intelligently selecting different implementation paths based on your current setup.  

Mortar aims to be distribution agnostic. Initial developments are on Arch Linux and Debian Linux.  

Security note: with TPM2 Clevis allows anyone with root access to fetch sufficent private data to decrypt the drive. Protect the root account. With TPM1.2 Mortar does some hacks to make this more difficult (thanks morbitzer).

## How it works.  

![mortar overview](docs/mortar-overview.svg)  

Only 2 partitions on your primary disk are used: your UEFI ESP, and your encrypted LUKS partition. (You can leave your unencrypted boot partition if you like, but I'd highly recommend removing or disabling its automatic mount so that kernels and initram filesystems can reside encrypted on your LUKS partition.)  

You generate your own Secureboot keys. Only efi files you sign will successfully boot without modifying the BIOS (and breaking PCR1 validation). 

## FAQ/Troubleshooting/Things To Watch For.  
If the EFI fails to boot, but external media still works: Make sure you enroll the hashes of your RAID cards and other media. The Dell BIOS on the R730 I tested with had a convenient way of doing this in the secureboot>custom>db>enrollment section of the BIOS. Authorizing hashes this way SHOULD (did on my system, make sure yours does!) change your PCR7 value, so check that and rebind your TPM state using the luks script if you make this change.  

TPM 1.2 errors accessing the index during boot: If using TPM 1.2, do not use "troublesome" characters in the Owner Password that would potentially cause errors when stored in a variable. Examples would include "/\$()*| " and such. Please *DO* make the passwords complex though. By re-running the luks script, you can opt to "own" the TPM device and change this password.  

## Installation (Debian with TPM 2 and LUKS 2 used for reference below).  

### Install Debian  
I used the netboot install method and let it configure most things for me. I selected the encrypted lvm on luks option and accepted all the default configurations.  

This gave me:  
Partition1: ESP 512MB  
Partition2: /boot 256MB  
Partition3: Encrypted LUKS (remainder of disk)  
  --> LVM /root (remainder -swap)  
  --> LVM swap (up to 8GB)  

As I mentioned earlier, we should **not** be using an unencrypted /boot when we're done.  

For your reference, this defaulted to xts-aes512. I'd recommend either using xts-aes512 (security-leaning sweet spot) or xts-aes256 (performance-leaning sweet spot) but that's up to you.  

You can test your expected performance of each with:  
    cryptsetup benchmark  

## Install the prerequisite software.
Do this as root in a directory only root can access. (I typically use /root/git at this stage.)  

Install git and git clone this project.  

    apt-get update && apt-get install git
    git clone https://github.com/noahbliss/mortar
    cd mortar
    ./0-initialsetup-prereqinstall.sh  

DON'T FORGET TO INSTALL THE TPM-VERSION-SPECIFIC PACKAGES THAT ARE ECHOED AT THE END.  
At this point you should have your /etc/mortar/mortar.env file generated and installed. Change any values that you'd like.  
/usr/local/sbin/mortar-compilesigninstall should also be installed.  

## Generate your secureboot keys.  
This spits out PEM formatted keys. If the script to install them fails, you may need to manually install them in your BIOS. Most BIOSes take DER format. You can convert them with the openssl command.  

    1-generatesecurebootkeys.sh  
Keys are written to /etc/mortar/private with sane permissions. The next command that sources mortar.env will further restrict these permissions.  

(more to come)
