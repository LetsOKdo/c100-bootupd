## Custom Bootloader for OKdo Nano C100

NVIDIA Jetson Nano Developer Kit (NDK) has the following hardware difference when compared to OKdo Nano C100:

* NDK contains SPI flash on the core module, while C100 uses production module with doesn't have this part populated.
* SD bus on NDK is SDMMC1, while on C100 is SDMMC3.

This means the following changes are required to boot unmodified NVIDIA image on SD card:

* U-Boot should enable SDMMC3 to load files from there.
* U-Boot should apply overlay to kernel dts to enable SDMMC3.
* U-Boot should modify `/etc/nv_boot_control.conf` to use eMMC boot partition as bootloader storage, not SPI flash.