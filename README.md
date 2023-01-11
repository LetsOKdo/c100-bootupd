## Custom Bootloader for OKdo Nano C100

NVIDIA Jetson Nano Developer Kit (NDK) has the following hardware difference when compared to OKdo Nano C100:

* NDK contains SPI flash on the core module, while C100 uses production module with doesn't have this part populated.
* SD bus on NDK is SDMMC1, while on C100 is SDMMC3.

This means the following changes are required to boot unmodified NVIDIA image on SD card:

* U-Boot should enable SDMMC3 to load files from there.
* U-Boot should apply overlay to kernel dts to enable SDMMC3.
* U-Boot should modify `/etc/nv_boot_control.conf` to use eMMC boot partition as bootloader storage, not SPI flash.
* U-Boot should modify `/boot/extlinux/extlinux.conf` to use SDMMC3 as rootfs.

However, due to U-Boot's incomplete ext4 write support, we will have to install a systemd unit to perform the step 3 instead.

## Build and installation

Please first download the following Jetson Linux R32.7.3 archives from [NVIDIA](https://developer.nvidia.com/embedded/linux-tegra-r3273):

* Driver Package (BSP): [Jetson-210_Linux_R32.7.3_aarch64.tbz2](https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2)
* Sample Root Filesystem: [Tegra_Linux_Sample-Root-Filesystem_R32.7.3_aarch64.tbz2](https://developer.nvidia.com/downloads/remeleasev73t210tegralinusample-root-filesystemr3273aarch64tbz2)
* [Optional] Driver Package (BSP) Sources: [public_sources.tbz2](https://developer.nvidia.com/downloads/remack-sdksjetpack-463r32releasev73sourcest210publicsourcestbz2)

Then please follow these steps to build and prepare your OKdo Nano C100:

```bash
./build-u-boot
# Put your C100 in recover mode
./flash-emmc
# Once the flash completes, C100 will reboot.
# Press Ctrl+C in serial console to interrupt U-Boot, and execute:
#     ums 0 0
# to mount internal eMMC on your computer.
# We assume it is shown as /dev/sdc
sudo mount /dev/sdc1 /mnt
./build-data
sudo ./flash-data
sudo umount /mnt
# In console, press Ctrl+C to interrupt ums command, and execute:
#     reset
# to reboot C100.
```