#!/usr/bin/env bash
source mortar.env
echo "Generating secureboot keys..."
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=PK$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_PK_KEY"  -out "$SECUREBOOT_PK_CRT"  -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=KEK$SECUREBOOT_MODIFIER/" -keyout "$SECUREBOOT_KEK_KEY" -out "$SECUREBOOT_KEK_CRT" -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=db$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_DB_KEY"  -out "$SECUREBOOT_DB_CRT"  -days 7300 -nodes -sha256

cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_PK_CRT" "$SECUREBOOT_PK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" PK "$SECUREBOOT_PK_ESL" "$SECUREBOOT_PK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_KEK_CRT" "$SECUREBOOT_KEK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" KEK "$SECUREBOOT_KEK_ESL" "$SECUREBOOT_KEK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_DB_CRT" "$SECUREBOOT_DB_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_KEK_KEY" -c "$SECUREBOOT_KEK_CRT" db "$SECUREBOOT_DB_ESL" "$SECUREBOOT_DB_AUTH"
