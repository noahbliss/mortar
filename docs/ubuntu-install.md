# Ubuntu Install Notes
## Ubuntu 18.04 LTS 
18.04 is missing package versions we need in its repositories. We need to manually install the versions we need. 
I fetched the following from the Debian stable repositories, the webpage https://packages.debian.org/index with Debian Buster as my distribution:
```
clevis
clevis-luks
clevis-tpm2
tpm2-tools
libtss2-esys0
libtss2-udev
```

Manually install these with `dpkg -i` after running step `0`. Once installed, I recommend a reboot then continue with the typical installation process. 
