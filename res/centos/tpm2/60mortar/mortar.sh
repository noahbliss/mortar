#!/bin/sh
# Noah Bliss
# Modified for github.com/noahbliss/mortar
# elements of this script inspired by https://github.com/latchset/clevis/blob/master/src/initramfs-tools/scripts/local-top/clevis.in as it existed on 1/14/2020

mkdir -p /run/cryptsetup
echo "Initializing... Please wait a few seconds for TPM validation of boot sequence."
echo "Measuring boot system integrity..."
cryptdev= #LUKS Partition /dev/sda3
cryptname= #Unlocked name (find in crypttab)
slotuuid= #OF THE KEYslot NOT THE DISK find with `luksmeta show -d /dev/nvmluks0p2` and check the slot uuid. 
slot= #Keyslot number for clevis.
headersha256=
headerfile=
tokenid=

# Test if the disk is already unlocked.
if [ -e /dev/mapper/"$cryptname" ]; then exit; fi
if ! [ -e "$cryptdev" ]; then echo "Cannot find the crypto device at $cryptdev"; exit 1; fi
sleep 2

# Verify the LUKS header.
if [ -f "$headerfile" ]; then rm "$headerfile"; fi
if cryptsetup luksHeaderBackup "$cryptdev" --header-backup-file "$headerfile"; then
    headersha256CUR=`sha256sum "$headerfile" | cut -f1 -d' '`
    if [ "$headersha256" == "$headersha256CUR" ]; then
        echo "HEADER VALIDATION SUCCEEDED."
    else
        echo "HEADER VALIDATION FAILED."
        echo "WAITING 10 SECONDS BEFORE CONTINUING."
        echo "KILL SYSTEM NOW IF YOU DO NOT TRUST THIS HEADER."
        sleep 7
        echo "3..."
        sleep 1
        echo "2..."
        sleep 1
        echo "1..."
        sleep 1
    fi
    sleep 2
fi

# Verify Secureboot and decrypt.

# If LUKS1
if cryptsetup isLuks --type luks1 "$cryptdev"; then
	if luksmeta load -d "$cryptdev" -s "$slot" -u "$slotuuid" | clevis decrypt | cryptsetup luksOpen "$cryptdev" "$cryptname"; then
		RESULT="pass"
	else
		RESULT="fail"
	fi
fi

# If LUKS2
if cryptsetup isLuks --type luks2 "$cryptdev"; then
	# jose jwe fmt -c outputs extra \n, so clean it up and pass to disk for unlocking.
	key=`cryptsetup token export --token-id "$tokenid" "$cryptdev" | jose fmt -j- -Og jwe -o- | jose jwe fmt -i- -c | tr -d '\n'`
	if echo -n "$key" | clevis decrypt | cryptsetup luksOpen "$cryptdev" "$cryptname"; then
		RESULT="pass"
	else
		RESULT="fail"
        fi
fi

# Display Result
if [ "$RESULT" == "pass" ]; then
    echo -e "TPM VALIDATION SUCCEEDED.\n\nI found $cryptname."
    sleep 2
else
    echo "TPM VALIDATION FAILED."
    sleep 3
fi

