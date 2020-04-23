#!/usr/bin/env bash
set -e
source /etc/mortar/mortar.env

failed() {
	echo "Failed to install $1. Is your secureboot in the BIOS configured for audit mode?"
}

installed() {
	echo "Installed $1."
}

chattr -i /sys/firmware/efi/efivars/{PK,KEK,db,dbx}-* 2>/dev/null
if (efi-updatevar -f "$SECUREBOOT_DB_AUTH" db); then thing="db"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_KEK_AUTH" KEK); then thing="KEK"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_PK_AUTH" PK); then thing="PK"; installed $thing; else failed $thing; exit 1; fi
echo "Secure boot keys installed. Double check that it is enforcing in the BIOS."
