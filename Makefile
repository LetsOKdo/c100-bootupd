PROJECT ?= c100-bootupd
PREFIX ?= /usr
ETCDIR ?= /etc
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
SHAREDIR ?= $(PREFIX)/share
MANDIR ?= $(SHAREDIR)/man
MNTDIR ?= /mnt

REUSE_SYSTEMIMG ?= 0

.PHONY: all
all: build

#
# Test
#
.PHONY: test
test:
	shellcheck src/c100-bootupd 

#
# Build
#
.PHONY: build
build: build-man build-doc build-data

SRC-U-BOOT	:= ./u-boot
U-BOOT		:= $(SRC-U-BOOT)/u-boot.bin
build-u-boot: $(U-BOOT)

$(SRC-U-BOOT)/u-boot.bin:
	cd u-boot && \
	git checkout tegra-l4t-r32.7.3 && \
	git am ../patches/*.patch
	make -j $(nproc) -C u-boot ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- p3450-0000_defconfig all

SRC-DATA	:= ./data
DATA		:= $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dtbo $(SRC-DATA)/u-boot-preboot.scr
build-data: $(DATA)

$(SRC-DATA)/tegra210-p3448-common-sdmmc3.dtbo: $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dts Linux_for_Tegra/source/kernel/hardware/nvidia/soc/tegra/kernel-include
	cpp -nostdinc -undef -x assembler-with-cpp -E -I "Linux_for_Tegra/source/kernel/hardware/nvidia/soc/tegra/kernel-include" $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dts $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dts.tmp
	dtc -O dtb -o "$@" -@ $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dts.tmp
	rm $(SRC-DATA)/tegra210-p3448-common-sdmmc3.dts.tmp

$(SRC-DATA)/u-boot-preboot.scr: $(SRC-DATA)/u-boot-preboot.cmd
	mkimage -C none -A arm64 -T script -d "$(SRC-DATA)/u-boot-preboot.cmd" "$@"

SRC-MAN		:=	./man
SRCS-MAN	:=	$(wildcard $(SRC-MAN)/*.md)
MANS		:=	$(SRCS-MAN:.md=)
.PHONY: build-man
build-man: $(MANS)

$(SRC-MAN)/%: $(SRC-MAN)/%.md
	pandoc "$<" -o "$@" --from markdown --to man -s

SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE $(SRC-DOC)/VERSION
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

.PHONY: $(SRC-DOC)/VERSION
$(SRC-DOC)/VERSION: $(SRC-DOC)
	dpkg-parsechangelog -S Version > "$@"

.PHONY: build-signed
build-signed: replace-u-boot
	cd Linux_for_Tegra && \
	sudo ./flash.sh --sign -r --no-flash jetson-nano-emmc mmcblk0p1

#
# Flash
#
Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot: $(U-BOOT)
	cp u-boot/u-boot Linux_for_Tegra/bootloader/t210ref/p3450-0000

Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot.bin: $(U-BOOT)
	cp u-boot/u-boot.bin Linux_for_Tegra/bootloader/t210ref/p3450-0000

Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot.dtb: $(U-BOOT)
	cp u-boot/u-boot.dtb Linux_for_Tegra/bootloader/t210ref/p3450-0000

Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot-dtb.bin: $(U-BOOT)
	cp u-boot/u-boot-dtb.bin Linux_for_Tegra/bootloader/t210ref/p3450-0000

.PHONY: replace-u-boot
replace-u-boot: Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot.bin Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot.dtb Linux_for_Tegra/bootloader/t210ref/p3450-0000/u-boot-dtb.bin

.PHONY: flash
flash: replace-u-boot
	cd Linux_for_Tegra && \
	if [ "$(REUSE_SYSTEMIMG)" == "1" ]; then \
		sudo ./flash.sh -r jetson-nano-emmc mmcblk0p1; \
	else \
		sudo ./flash.sh jetson-nano-emmc mmcblk0p1; \
	fi

.PHONY: flash-u-boot
flash-u-boot: replace-u-boot
	cd Linux_for_Tegra && \
	sudo ./flash.sh -k LNX jetson-nano-emmc mmcblk0p1

.PHONY: flash-u-boot
flash-data: $(DATA) $(SRC-DATA)/nv_boot_control.conf $(SRC-DATA)/nv_boot_control.service
	sudo cp "$(SRC-DATA)/nv_boot_control.conf" "$(MNTDIR)/etc/nv_boot_control.conf"
	sudo cp "$(SRC-DATA)/nv_boot_control.service" "$(MNTDIR)/etc/systemd/system/nv_boot_control.service"
	sudo cp "$(SRC-DATA)/tegra210-p3448-common-sdmmc3.dtbo" "$(MNTDIR)/boot/tegra210-p3448-common-sdmmc3.dtbo"
	sudo cp "$(SRC-DATA)/u-boot-preboot.scr" "$(MNTDIR)/u-boot-preboot.scr"
	sync

#
# Clean
#
.PHONY: distclean
distclean: clean
	make -C u-boot ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- distclean

.PHONY: clean
clean: clean-man clean-doc clean-deb clean-u-boot clean-data
	make -C u-boot ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- clean

.PHONY: clean-man
clean-man:
	rm -rf $(MANS)

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

.PHONY: clean-u-boot
clean-u-boot:
	rm -rf $(U_BOOT)

.PHONY: clean-data
clean-data:
	rm -rf $(DATA)

#
# Release
#
.PHONY: dch
dch: debian/changelog
	gbp dch --debian-branch=main

.PHONY: deb
deb: debian build-signed
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

sd-blob-b01.img: jetson-nano-jp461-sd-card-image.zip
	unzip $<
	touch $@

.PHONY: image
image: deb sd-blob-b01.img
	cp sd-blob-b01.img c100.img
	sudo kpartx -a c100.img
	sudo mount /dev/mapper/loop0p1 $(MNTDIR)
	sudo cp ../$(PROJECT)*.deb $(MNTDIR)
	sudo systemd-nspawn -D $(MNTDIR) bash -c "dpkg -i /$(PROJECT)*.deb"
	sudo umount $(MNTDIR)
	sudo kpartx -d c100.img
