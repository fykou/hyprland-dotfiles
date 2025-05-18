#!/usr/bin/env bash

flg_DryRun=${flg_DryRun:-0}

export log_section="extract"
if ! source "${SCR_DIR}/Scripts/global_fn.sh"; then
    echo -e "\e[31mError: unable to source global_fn.sh...\e[0m"
    exit 1
fi

while read -r lst; do
    # Skip lines starting with #
    if [[ "$lst" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    # Check if the line has the correct number of fields
    if [ "$(echo "$lst" | awk -F '|' '{print NF}')" -ne 2 ]; then
        continue
    fi

    fnt=$(awk -F '|' '{print $1}' <<<"$lst")
    tgt=$(awk -F '|' '{print $2}' <<<"$lst")
    tgt=$(eval "echo $tgt")


    if [ ! -d "${tgt}" ]; then
        if ! mkdir -p "${tgt}"; then
            print_log -warn "create" "directory as root instead..."
            [ "${flg_DryRun}" -eq 1 ] || sudo mkdir -p "${tgt}"
        fi

    fi

    if [ -w "${tgt}" ]; then
        [ "${flg_DryRun}" -eq 1 ] || tar -xzf "${cloneDir}/Source/arcs/${fnt}.tar.gz" -C "${tgt}/"
    else
        print_log -warn "not writable" "Extracting as root: ${tgt} "
        if [ "${flg_DryRun}" -ne 1 ]; then
            if ! sudo tar -xzf "${cloneDir}/Source/arcs/${fnt}.tar.gz" -C "${tgt}/" 2>/dev/null; then
                print_log -err "extraction by root FAILED" " giving up..."
                print_log "The above error can be ignored if the '${tgt}' is not writable..."
            fi
        fi
    fi
    print_log "${fnt}.tar.gz" -r " --> " "${tgt}... "

done <"${SCR_DIR}/restore_fnt.lst"
echo ""
print_log -stat "rebuild" "font cache"
[ "${flg_DryRun}" -eq 1 ] || fc-cache -f
