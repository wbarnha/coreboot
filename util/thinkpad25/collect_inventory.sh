#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Read-only stock-firmware inventory for ThinkPad 25 port preparation.
set -eu
umask 077
if [ "${1:-}" = "--help" ]; then
	printf 'Usage: sudo bash %s\nCollects a private inventory archive in the current directory. No SPI access.\n' "$0"
	exit 0
fi
if [ "$#" -ne 0 ]; then
	printf 'Unexpected argument. Use --help for usage.\n' >&2
	exit 2
fi
kind=thinkpad25
product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
case "$product" in
	20K7*) ;;
	*) printf 'Wrong target: requested %s, DMI product is %s. Nothing collected.\n' "$kind" "$product" >&2; exit 2 ;;
esac
if [ "$(id -u)" -ne 0 ]; then printf 'Run with sudo to read ACPI/DMI tables.\n' >&2; exit 2; fi
out=$(mktemp -d "$PWD/coreboot-inventory-$kind.XXXXXX")
mkdir -p "$out/dmi" "$out/drm" "$out/audio" "$out/acpi-tables" "$out/acpi-tables/dynamic"
printf 'Target: %s\nProduct: %s\nUTC: %s\n' "$kind" "$product" "$(date -u +%FT%TZ)" > "$out/identity.txt"
capture() {
	name=$1; shift
	if command -v "$1" >/dev/null 2>&1; then
		"$@" > "$out/$name" 2>&1 || true
	else
		printf 'Missing tool: %s\n' "$1" > "$out/$name"
	fi
}
capture hostname.txt hostname
capture uname.txt uname -a
capture lscpu.txt lscpu
capture lspci-nnvv.txt lspci -nnvv
capture lsusb.txt lsusb
capture dmidecode.txt dmidecode
capture lshw-short.txt lshw -short
capture acpi.out acpidump
# Raw sysfs ACPI tables remain available even when acpidump is not installed.
for p in /sys/firmware/acpi/tables/*; do
	if [ -f "$p" ] && [ -r "$p" ]; then
		cat "$p" > "$out/acpi-tables/$(basename "$p")" || true
	fi
done
for p in /sys/firmware/acpi/tables/dynamic/*; do
	if [ -f "$p" ] && [ -r "$p" ]; then
		cat "$p" > "$out/acpi-tables/dynamic/$(basename "$p")" || true
	fi
done
for p in /sys/class/drm/card*-*/status; do
	if [ -r "$p" ]; then
		name=$(basename "$(dirname "$p")"); cat "$p" > "$out/drm/$name.status.txt" || true
	fi
done
for n in bios_vendor bios_version bios_date bios_release ec_firmware_release sys_vendor product_name product_version board_vendor board_name board_version chassis_vendor chassis_type; do
	if [ -r "/sys/class/dmi/id/$n" ]; then cat "/sys/class/dmi/id/$n" > "$out/dmi/$n.txt"; fi
done
for n in DMI smbios_entry_point; do
	if [ -r "/sys/firmware/dmi/tables/$n" ]; then cat "/sys/firmware/dmi/tables/$n" > "$out/dmi/$n.bin"; fi
done
for p in /sys/class/drm/card*-*/edid; do
	if [ -r "$p" ]; then name=$(basename "$(dirname "$p")"); cat "$p" > "$out/drm/$name.edid" || true; fi
done
for p in /proc/asound/card*/codec*; do
	if [ -r "$p" ]; then name=$(basename "$(dirname "$p")")-$(basename "$p"); cat "$p" > "$out/audio/$name.txt" || true; fi
done
printf '%s\n' 'Inventory only: no flashrom, SPI access, updater, MSR/PCI writes, GPIO changes or fuse operations performed.' > "$out/READ_ME.txt"
printf '%s\n' 'DMI and firmware tables can contain serial numbers, UUIDs and Windows licensing data. Treat this archive as private.' >> "$out/READ_ME.txt"
archive="$out.tar.gz"
tar -C "$out" -czf "$archive" .
case "${SUDO_UID:-}:${SUDO_GID:-}" in
	*[!0-9:]*|:*) ;;
	*) chown -R "$SUDO_UID:$SUDO_GID" "$out" "$archive" ;;
esac
printf 'Created private inventory: %s\n' "$archive"
sha256sum "$archive"
