#!/bin/bash

if ! { [[ -d /etc/dkms ]] && [[ -x "$(command -v dkms)" ]] && \
[[ -r /etc/dkms/framework.conf ]] ; } ; then
    >&2 echo "No working installation of DKMS framework found. Skipping setup."
    exit 0
fi

hook_script="/var/lib/secureboot/dkms/chain-sign-hook.conf"
[[ -e "$hook_script" ]] || {
    >&2 echo "Hook script is not installed!"
    exit 1
}

dkms_tree="/var/lib/dkms"
. /etc/dkms/framework.conf

dkms_status="$(dkms status)"

# parse dkms status
shopt -s extglob
i=0
while read -r line ; do
    IFS=',' read -ra arr <<< "$line"
    module[$i]="${arr[0]}"
    version[$i]="${arr[1]##+([[:space:]])}"
    kernelver[$i]="${arr[2]##+([[:space:]])}"
    arch_status="${arr[3]##+([[:space:]])}"
    IFS=':' read -ra arch_status_arr <<< "$arch_status"
    arch[$i]="${arch_status_arr[0]}"
    status[$i]="${arch_status_arr[1]##+([[:space:]])}"
    [[ "${module[$i]}" ]] && [[ "${version[$i]}" ]] && [[ "${kernelver[$i]}" ]] \
    && [[ "${arch[$i]}" ]] && [[ "${#arr[@]}" = 4 ]] && \
    [[ "${#arch_status_arr[@]}" = 2 ]] && [[ "${status[$i]}" =~ installed ]] && \
        (( i++ ))
done <<< "$dkms_status"

mod_count="$i"

flagdir="$(mktemp -d)"
cleanup () {
    rm -rf "$flagdir"
}
trap cleanup EXIT

# install hooks for modules
for ((i=0; i<mod_count; i++)) ; do
    modconf="/etc/dkms/${module[$i]}.conf"
    if [[ -e "$flagdir/${module[$i]}.conf_installed" ]] ; then
        continue
    else
        if [[ -e "$modconf" ]] || [[ -h "$modconf" ]] ; then
            if [[ -e "$flagdir/${module[$i]}.merge_notify" ]] ; then
                continue
            else
                >&2 echo "Module ${module[$i]} already has user override."
                >&2 echo "Please do manual merge with $hook_script."
                :> "$flagdir/${module[$i]}.merge_notify"
            fi
        else
            ln -s "$hook_script" "$modconf"
            :> "$flagdir/${module[$i]}.conf_installed"
        fi
    fi
done

# rebuild all modules one by one
for ((i=0; i<mod_count; i++)) ; do
    [[ -e "$flagdir/${module[$i]}.conf_installed" ]] || continue
    >&2 echo "rebuilding module='${module[$i]}' version='${version[$i]}'" \
    "kernelver='${kernelver[$i]}' arch='${arch[$i]}'"
    dkms uninstall -m "${module[$i]}" -v "${version[$i]}" -k "${kernelver[$i]}" -a "${arch[$i]}"
    # clean build artifacts to ensure rebuild will take place
    rm -rf "${dkms_tree:?}/${module[$i]}/${version[$i]}/${kernelver[$i]}/${arch[$i]}/"
    dkms install -m "${module[$i]}" -v "${version[$i]}" -k "${kernelver[$i]}" -a "${arch[$i]}"
done

# cleanup
exit 0
