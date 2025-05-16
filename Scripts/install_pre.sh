#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}

# systemd-boot configuration
if pkg_installed systemd && nvidia_detect && [ "$(bootctl status 2>/dev/null | awk '{if ($1 == "Product:") print $2}')" == "systemd-boot" ]; then
    print_log -sec "bootloader" -stat "detected" "systemd-boot"

    entry_count=$(find /boot/loader/entries/ -type f -name '*.conf.okef.bkp' 2>/dev/null | wc -l)
    total_count=$(find /boot/loader/entries/ -type f -name '*.conf' 2>/dev/null | wc -l)

    if [ "$entry_count" -ne "$total_count" ]; then
        print_log -g "[bootloader] " -b " :: " "nvidia detected, updating boot options..."

        find /boot/loader/entries/ -type f -name "*.conf" | while read -r imgconf; do
            sudo cp "${imgconf}" "${imgconf}.okef.bkp"
            sdopt=$(grep -w "^options" "${imgconf}" \
                | sed 's/\b quiet\b//g' \
                | sed 's/\b splash\b//g' \
                | sed 's/\b nvidia_drm.modeset=.\b//g' \
                | sed 's/\b nvidia_drm.fbdev=.\b//g')
            sudo sed -i "/^options/c${sdopt} quiet splash nvidia_drm.modeset=1 nvidia_drm.fbdev=1" "${imgconf}"
        done
    else
        print_log -y "[bootloader] " -stat "skipped" "systemd-boot is already configured..."
    fi
fi

# Add NVIDIA modprobe options
NVEA="/etc/modprobe.d/nvidia.conf"
if [[ ! -f "$NVEA" ]]; then
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee "$NVEA"
    print_log -sec "kernel modules" -stat "configured" "Added nvidia_drm options to modprobe.d"
fi

# Regenerate initramfs
print_log -sec "initramfs" -stat "regenerating" "Running mkinitcpio..."
sudo mkinitcpio -P

# Optionally blacklist Nouveau
if command -v gum &>/dev/null && gum confirm "Would you like to blacklist the Nouveau driver?"; then
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau.conf
    echo "install nouveau /bin/true" | sudo tee /etc/modprobe.d/blacklist.conf
    print_log -sec "nouveau" -stat "blacklisted" "Nouveau driver has been disabled"
else
    print_log -sec "nouveau" -stat "skipped" "Nouveau driver not blacklisted"
fi


# pacman
if [ -f /etc/pacman.conf ] && [ ! -f /etc/pacman.conf.okef.bkp ]; then
    print_log -g "[PACMAN] " -b "modify :: " "adding extra spice to pacman..."

    [ "${flg_DryRun}" -eq 1 ] || sudo cp /etc/pacman.conf /etc/pacman.conf.okef.bkp
    [ "${flg_DryRun}" -eq 1 ] || sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    [ "${flg_DryRun}" -eq 1 ] || sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf

    print_log -g "[PACMAN] " -b "update :: " "packages..."
    [ "${flg_DryRun}" -eq 1 ] || sudo pacman -Syyu
    [ "${flg_DryRun}" -eq 1 ] || sudo pacman -Fy
else
    print_log -sec "PACMAN" -stat "skipped" "pacman is already configured..."
fi

