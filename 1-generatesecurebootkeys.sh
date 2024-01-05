#!/usr/bin/env bash
set -e
MORTAR_FILE="/etc/mortar/mortar.env"
source "$MORTAR_FILE"
echo "Generating secureboot keys..."
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=PK$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_PK_KEY"  -out "$SECUREBOOT_PK_CRT"  -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=KEK$SECUREBOOT_MODIFIER/" -keyout "$SECUREBOOT_KEK_KEY" -out "$SECUREBOOT_KEK_CRT" -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=db$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_DB_KEY"  -out "$SECUREBOOT_DB_CRT"  -days 7300 -nodes -sha256
# Adding der versions of keys to private dir.
openssl x509 -in "$SECUREBOOT_PK_CRT" -outform der -out "$SECUREBOOT_PK_CRT".der
openssl x509 -in "$SECUREBOOT_KEK_CRT" -outform der -out "$SECUREBOOT_KEK_CRT".der
openssl x509 -in "$SECUREBOOT_DB_CRT" -outform der -out "$SECUREBOOT_DB_CRT".der

# Generate secureboot specific file variants.
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_PK_CRT" "$SECUREBOOT_PK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" PK "$SECUREBOOT_PK_ESL" "$SECUREBOOT_PK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_KEK_CRT" "$SECUREBOOT_KEK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" KEK "$SECUREBOOT_KEK_ESL" "$SECUREBOOT_KEK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_DB_CRT" "$SECUREBOOT_DB_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_KEK_KEY" -c "$SECUREBOOT_KEK_CRT" db "$SECUREBOOT_DB_ESL" "$SECUREBOOT_DB_AUTH"

echo "You now need to generate/install a signed efi file Before installing the keys and enabling secureboot!"
echo "Run bin/mortar-compilesigninstall FULLPATHTOKERNELIMAGE FULLPATHTOINITRDIMAGE"
