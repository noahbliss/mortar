# Debian Install Notes  

Debian is a first-class development target for mortar and as such is the most thoroughly tested and frequently installed by the developer.  

## Gotcha's  
Everyone knows the bane of Debian is old packages in the name of stability. This bites us a little with mortar.  

**If you are using a TPM2 module and step `3-` fails due to errors _before_ asking for your LUKS password...**  
Run `tpm2_pcrlist` and check which banks (hash types) are being used. If _only one_ type (likely sha1 or sha256) is showing PCR values, you're probably encountering a bug in the Debian version of clevis where it complains about filesizes. My error was "ERROR: pcr-input-file filesize does not match pcr set-list"  

You can bypass this by doing the following:  
`cd` into the mortar directory.  

to be continued... but basically you get clevis-encrypt-tpm2 from the upstream dev's [github page](https://github.com/latchset/clevis/blob/master/src/pins/tpm2/clevis-encrypt-tpm2) and install that manually before step 3. You should be able to revert the file after you run step 3.  
