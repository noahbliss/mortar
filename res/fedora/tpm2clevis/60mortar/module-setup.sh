#!/bin/bash
# Noah Bliss

depends()
{
     echo "crypt systemd"
     return 0
}

cmdline() {
	return 0
}

# Main script
install () {

inst_hook initqueue/settled 60 "$moddir/mortar.sh"

f=clevis; inst $f || echo "$f not found"
f=clevis-decrypt-tang; inst $f || echo "$f not found"
f=clevis-decrypt-sss; inst $f || echo "$f not found"
f=clevis-decrypt; inst $f || echo "$f not found"
f=clevis-decrypt-tpm2; inst $f || echo "$f not found"

tpm2_creatprimary_bin=$(command -v "tpm2_createprimary")
tpm2_unseal_bin=$(command -v "tpm2_unseal")
tpm2_load_bin=$(command -v "tpm2_load")
inst "${tpm2_creatprimary_bin}" || echo "Unable to copy ${tpm2_creatprimary_bin}" 
inst "${tpm2_unseal_bin}" || echo "Unable to copy ${tpm2_unseal_bin}"
inst "${tpm2_load_bin}" || echo "Unable to copy ${tpm2_load_bin}"
# Future-proof ourselves if tpm2-tools gets upgraded to 4. 
tpm2_pcrget_bin=$(command -v tpm2_pcrlist)
if [ -z "$tpm2_pcrget_bin" ]; then tpm2_pcrget_bin=$(command -v tpm2_pcrread); fi
if [ -z $tpm2_pcrget_bin ]; then echo "Unable to find a tpm2 bin to read pcrs."; fi
inst "${tpm2_pcrget_bin}" || echo "Unable to copy ${tpm2_pcrget_bin}"
inst_libdir_file "libtss2-tcti-device.so*"


luksmeta_bin=$(command -v "luksmeta")
jose_bin=$(command -v "jose")
bash_bin=$(command -v "bash")
inst "${luksmeta_bin}" || echo "Unable to copy ${luksmeta_bin}"
inst "${jose_bin}" || echo "Unable to copy ${jose_bin}"
inst "${bash_bin}" || echo "Unable to copy ${bash_bin} to initrd image"

dracut_need_initqueue
}

installkernel() {
	hostonly='' instmods =drivers/char/tpm

	#manual_add_modules tpm
	#manual_add_modules tpm_crb
	#manual_add_modules tpm_tis
	#manual_add_modules tpm_tis_core
}
