echo ============
echo [C100] Checking if microSD is available...
echo ============
if mmc dev 1
then
    if test ! -e mmc 1:1 /etc/systemd/system/nv_boot_control.service
    then
        echo ============
        echo [C100] Installing nv_boot_control.conf...
        echo ============
        load mmc 0:1 ${scriptaddr} /etc/nv_boot_control.conf
        save mmc 1:1 ${scriptaddr} /usr/local/share/nv_boot_control.conf ${filesize}
        echo ============
        echo [C100] Installing nv_boot_control.service...
        echo ============
        load mmc 0:1 ${scriptaddr} /etc/systemd/system/nv_boot_control.service
        save mmc 1:1 ${scriptaddr} /etc/systemd/system/nv_boot_control.service ${filesize}
        ln mmc 1:1 ../nv_boot_control.service /etc/systemd/system/nv-oem-config.target.wants/nv_boot_control.service
    fi

    if test ! -e mmc 1:1 /boot/tegra210-p3448-common-sdmmc3.dtbo
    then
        echo ============
        echo [C100] Installing tegra210-p3448-common-sdmmc3.dtbo...
        echo ============
        load mmc 0:1 ${scriptaddr} /boot/tegra210-p3448-common-sdmmc3.dtbo
        save mmc 1:1 ${scriptaddr} /boot/tegra210-p3448-common-sdmmc3.dtbo ${filesize}
    fi

    if test ! -e mmc 1:1 /boot/tegra210-porg-p3448-emc-a00.dtbo
    then
        echo ============
        echo [C100] Installing tegra210-porg-p3448-emc-a00.dtbo...
        echo ============
        load mmc 0:1 ${scriptaddr} /boot/tegra210-porg-p3448-emc-a00.dtbo
        save mmc 1:1 ${scriptaddr} /boot/tegra210-porg-p3448-emc-a00.dtbo ${filesize}
    fi
fi