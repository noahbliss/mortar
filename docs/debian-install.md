# Debian Install Notes  

Debian is a first-class development target for mortar and as such is the most thoroughly tested and frequently installed by the developer.  

## Gotcha's  
Everyone knows the bane of Debian is old packages in the name of stability. This bites us a little with mortar.  

Debian installed from the Live disk with encryption is **not** supported currently. It sets up the boot chain differently than the netinstall.  

**If you are using a TPM2 module and step `3-` fails due to errors _before_ asking for your LUKS password...**  
Run `tpm2_pcrlist` and check which banks (hash types) are being used. If _only one_ type (likely sha1 or sha256) is showing PCR values, you're probably encountering a bug in the Debian version of clevis where it complains about filesizes. My error was "ERROR: pcr-input-file filesize does not match pcr set-list"  

You can bypass this by doing the following:  
`cd` into the mortar directory.  

From here we'll grab `clevis-encrypt-tpm2` from the upstream development github, drop that in our system, run step 3, then restore the old file. [Clevis github page](https://github.com/latchset/clevis/blob/master/src/pins/tpm2/clevis-encrypt-tpm2)

```
if [ $UID -eq 0 ]; then
binpath=$(command -v clevis-encrypt-tpm2)
cp "$binpath" "$binpath.bak"
wget https://raw.githubusercontent.com/latchset/clevis/master/src/pins/tpm2/clevis-encrypt-tpm2 -O "$binpath"
#RUN STEP 3 from mortar.
#When it's done and working as expected you can restore the old file with:
#binpath=$(command -v clevis-encrypt-tpm2); mv "$binpath".bak "$binpath"
fi
```
