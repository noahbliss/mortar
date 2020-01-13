# Debian

ENVFILE="/etc/mortar/mortar.env" #Don't want to use $0 since we are using source against this file all over the place.
WORKING_DIR='/etc/mortar/'
PRIVATE_DIR="$WORKING_DIR/private/"
if [ "$UID" -ne "0" ]; then echo "Must be run as root."; exit 1; fi
mkdir -p "$PRIVATE_DIR"
chown root:root -R "$PRIVATE_DIR"
chmod go-rwx -R "$PRIVATE_DIR"
chmod go-rwx -R "$WORKING_DIR"
cd "$WORKING_DIR"

# Install the env file with a random key_uuid if it doesn't exist.
if ! [ -f "$ENVFILE" ]; then KEY_UUID=$(uuidgen --random); sed -i -e "/KEY_UUID=/{s//KEY_UUID=$KEY_UUID/;:a" -e '$!N;$!ba' -e '}' mortar.env > "$ENVFILE"; fi

# Figure out our distribuition. 
source /etc/os-release

# Debian
if [ "$ID" == "debian" ]; then
	apt-get update
	apt-get install \
		binutils \
		efitools

	echo "Installed Debian dependencies."
fi

# Arch
if [ "$ID" == "arch" ]; then
	pacman -Sy binutils \
		efitools

	echo "Installed Arch dependencies."
fi

