## Custom created image to use on an SD card for OKdo nano C100

Click [Here](https://auto.designspark.info/okdo_images/c100.img.xz) to download the image. Use your usual flashing tool to flash the image it to the SD card.

If you don't have a tool, then here is a how to: https://www.okdo.com/getting-started/get-started-with-jetson-nano-4gb-and-csi-camera/#h-2-flash-microsd-card-toc

If you are using the C100 for the first time this is all you have to do.


## Custom Bootloader for OKdo Nano C100
This instruction is only needed if you want to “reset” the eMMC on the C100 to the state it had from the factory. 

## Background

NVIDIA Jetson Nano Developer Kit (NDK) has the following hardware difference when compared to OKdo Nano C100:

* NDK contains SPI flash on the core module, while C100 uses production module with doesn't have this part populated.
* SD bus on NDK is SDMMC1, while on C100 is SDMMC3.

This means the following changes are required to boot unmodified NVIDIA image on SD card:

* U-Boot should enable SDMMC3 to load files from there.
* U-Boot should apply overlay to kernel dts to enable SDMMC3.
* U-Boot should modify `/etc/nv_boot_control.conf` to use eMMC boot partition as bootloader storage, not SPI flash.
* U-Boot should modify `/boot/extlinux/extlinux.conf` to use SDMMC3 as rootfs.

However, due to U-Boot's incomplete ext4 write support, we will have to install a systemd unit to perform the step 3 instead.

Another issue is that NVIDIA kernel specified 1.8V UHS mode, which is not supported in U-Boot. UHS mode [presists after soft reset](https://forums.developer.nvidia.com/t/jetson-nano-warm-resets-fail-with-u-boot-no-partition-table-errors/192511) so U-Boot cannot read SD card after reboot.

As such, we have to completely delete the old SDMMC3 node (device tree overlay cannot delete node or property), and recreate it in our overlay. We also disabled voltage regultor to switch signal voltage to 1.8V. A side effect is that SDMMC3 then becomes `mmcblk0`, which allowed us to skip step 4.

## Build dependency

```
sudo apt update
sudo apt install build-essential bison flex git
# When building from x86 systems, you will also need the following crossbuild depenencies
sudo apt install crossbuild-essential-arm64 qemu-user-static binfmt-support
```

## Build and installation

This repo contains git submodule. As such please use the following command to clone it:

```
git clone --recurse-submodules https://github.com/LetsOKdo/c100-bootupd.git
```

Please first download the following Jetson Linux R32.7.3 archives from [NVIDIA](https://developer.nvidia.com/embedded/linux-tegra-r3273) and put them under this project's folder:

* Driver Package (BSP): [Jetson-210_Linux_R32.7.3_aarch64.tbz2](https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2)
* Sample Root Filesystem: [Tegra_Linux_Sample-Root-Filesystem_R32.7.3_aarch64.tbz2](https://developer.nvidia.com/downloads/remeleasev73t210tegralinusample-root-filesystemr3273aarch64tbz2)
* Driver Package (BSP) Sources: [public_sources.tbz2](https://developer.nvidia.com/downloads/remack-sdksjetpack-463r32releasev73sourcest210publicsourcestbz2)

The following steps then prepare your OKdo Nano C100 for both eMMC and microSD booting:

```bash
# Run the following command to set up Linux for Tegra
# Only need to run once!
./init-jetpack
# Put your C100 in recover mode first
make flash
# Once the flash completes, C100 will reboot and contains a working system in eMMC.
# ################################
# If you want to enable microSD booting, please follow the reset of the guide:
# ################################
# Press Ctrl+C in serial console to interrupt U-Boot, and execute:
#     ums 0 0
# to mount internal eMMC on your computer.
# We assume it is shown as /dev/sdc
sudo mount /dev/sdc1 /mnt
make flash-data
sudo umount /mnt
# In console, press Ctrl+C to interrupt ums command, and execute:
#     reset
# to reboot C100.
```

## Create bootloader update image

Currently the image is based on the official [JetPack 4.6.1 image](https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/jp_4.6.1_b110_sd_card/jeston_nano/jetson-nano-jp461-sd-card-image.zip).

The following steps create a modified microSD image that can be used to automatically update eMMC bootloader:

```bash
# Install build dependencies for Debian package
# Only need to run once!
sudo apt install build-dep .
# Uncompress the original image as sd-blob-b01.img
make image
```
