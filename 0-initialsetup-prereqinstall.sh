# Debian

ENVFILE="/etc/mortar/mortar.env" #Don't want to use $0 since we are using source against this file all over the place.
CMDLINEFILE="/etc/mortar/cmdline.conf"
WORKING_DIR='/etc/mortar/'
PRIVATE_DIR="$WORKING_DIR/private/"
if [ "$UID" -ne "0" ]; then echo "Must be run as root."; exit 1; fi
mkdir -p "$PRIVATE_DIR"
chown root:root -R "$PRIVATE_DIR"
chmod go-rwx -R "$PRIVATE_DIR"
chmod go-rwx -R "$WORKING_DIR"

# Figure out our distribuition. 
source /etc/os-release

# Debian
if [ "$ID" == "debian" ]; then
	apt-get update
	apt-get install \
		binutils \
		efitools \
		uuid-runtime

	echo "Installed Debian dependencies."
fi

# Arch
if [ "$ID" == "arch" ]; then
	pacman -Sy binutils \
		efitools \
		util-linux \
		sbsigntools

	echo "Installed Arch dependencies."
fi

# Install the env file with a random key_uuid if it doesn't exist.
if ! (command -v uuidgen >/dev/null); then echo "Cannot find uuidgen tool."; exit 1; fi
if ! [ -f "$ENVFILE" ]; then echo "Generating new KEY_UUID and installing mortar.env to $WORKING_DIR"; KEY_UUID=$(uuidgen --random); sed -e "/KEY_UUID=/{s//KEY_UUID=$KEY_UUID/;:a" -e '$!N;$!ba' -e '}' mortar.env > "$ENVFILE"; else echo "mortar.env already installed in $WORKING_DIR"; fi

# Install cmdline.conf
if ! [ -f "$CMDLINEFILE" ]; then echo "No CMDLINE options file found. Using currently running cmdline options from /proc/cmdline"; cat /proc/cmdline > "$CMDLINEFILE"; else echo "cmdline.conf already installed in $WORKING_DIR"; fi
echo "Make sure to update the installed mortar.env with your TPM version and ensure all the paths are correct."


# TPM VERSION SPECIFIC PACKAGES.

## Debian
# tpm2-tools clevis-tpm2 clevis-luks

## Arch
# tpm2-tools clevis

