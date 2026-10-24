# ThinkPad 25: Libreboot 25.06 experiment

## Current evidence

On 2026-10-24 a locally adapted, pinned Libreboot 25.06 T480-derived image
was programmed on an original ThinkPad 25 (20K70004US, i7-7500U, 940MX).
The W25Q128JV identified as EF4018 / 16 MiB. Full original reads matched.
Programming completed with flashrom verification, followed by a separate
full readback that matched the approved image byte-for-byte.

Installed image size: 16,777,216 bytes. Installed image/readback SHA-256:

```
42051825518a236c48165f11c6d226097a557a70b9a5b34fc04816be4bcdc8b9
```

The user initially reported no HDMI output, with other behavior seeming
okay. A later user-supplied photograph shows:

- the Libreboot 25.06 SeaBIOS menu rendered on a display;
- USB mass-storage boot entries;
- GRUB loading and welcome text after a boot-device handoff.

The user clarifies that the screen remained frozen at the GRUB welcome
text for several minutes; the OS never appeared. In the photo, SeaBIOS shows
its countdown proceeding to “Booting from Hard Disk” before the GRUB loading
and welcome text. This points to a hang during the hard disk's GRUB startup,
before OS handoff. The photo's SeaBIOS menu separately listed USB devices
and a `Payload [grub2]` entry; explicitly selecting that payload or a known
bootable USB device would distinguish the disk bootloader path from the
firmware's GRUB payload. No kernel messages or OS startup are visible. Keyboard operation,
all memory, charging, thermals, suspend, docking, audio, USB-C/Thunderbolt
and GPU behavior are not independently validated. The photo's display
connection is unknown, so it does not resolve the earlier HDMI result.
The photograph and visible machine UUID remain private.

## Baseline and source changes

The [source overlay](../../../util/thinkpad25/libreboot2506/README.md)
records the local code changes, resolved configuration and layout. It targets
lbmk `c46a71138c77556b103a4a5c85917d5bb5cc915a`, coreboot base
`c247f62749b967143e58c33aa0e5e234711a628f` plus all 42 release patches,
and deguard `de176a7f20650b272a01efb633931a63128c1647`.
The dependency commits and release patch hashes are pinned alongside it.
This source overlay is not directly applicable to this fork's newer mainboard
implementation and does not add an upstream supported-board selector.

Local changes:

- Replace the donor ALC257 verb table with ALC298/HDMI pin defaults captured
  under stock Linux. No vendor coefficients or amplifier behavior inferred.
- Skip T480-specific debug UART configuration when serial console is disabled.
- Use a 7 MiB CBFS and a layout preserving the original stock-data area.
- Provide a bounded, CBFS-backed SMBIOS adapter for the captured identity.
- Retain the exact ten-byte IED signature using an explicit initializer for
  compatibility with the GCC 15 toolchain.

The release's SeaBIOS framebuffer payload, GRUB/memtest secondary payloads,
VGA BIOS and companion settings were retained byte-identically. FSP input
hashes match the pinned release requirements. Inserted FSP-M XIP relocation
was independently reproduced with Intel's pinned tool; FSP-S is unchanged.
A second assembly matched the installed image hash. This verifies assembly
from recorded inputs, not an independently repeated compiler build.

## Machine-data preservation and intentional changes

| Region | File range, inclusive | Treatment |
| --- | --- | --- |
| Descriptor | 0x000000–0x000FFF | Original except HAP bit at 0x102 |
| GbE | 0x001000–0x002FFF | Byte-identical, including board MAC/configuration |
| ME | 0x003000–0x6FFFFF | Reconstructed Consumer LP 11.6.0.1126 for deguard |
| Stock data | 0x700000–0x89FFFF | Byte-identical NVRAM/configuration/embedded EC update copy |
| FMAP/reserved | 0x8A0000–0x8AFFFF | New layout metadata/reserved bytes |
| MRC cache | 0x8B0000–0x8BFFFF | Initially erased; runtime training may write here |
| Reserved | 0x8C0000–0x8FFFFF | Initially erased |
| Coreboot | 0x900000–0xFFFFFF | Code, payloads and archival originals |

The active ME uses this board's own delta rather than the T480 delta:
30 retained entries were checked, with EOM intentionally changed from 01
to 00. Five secureboot overrides were excluded for the zero SRAM FPF
construction; no physical fuse change, red-unlock option or DCI enablement
was requested. Full original ME contents and descriptor are archived inside
the candidate, while the complete original dump remains the rollback image.
Runtime ME/PTT state is archived rather than transplanted wholesale.

Captured serials, UUID, SKU, versions and product names are supplied by a
private CBFS identity record; the exact captured MSDM ACPI table is retained.
Stock NVRAM bytes remain present but are not coreboot's active settings
backend. Original Secure Boot enforcement and TPM sealed-state behavior
are not preserved by archiving their data. TPM is disabled for this experiment;
SMT remains disabled as in the pinned release. No separate EC firmware was
flashed. Firmware images, identities, MSDM keys, raw ACPI/SMBIOS, inventories,
ME deltas and programmer logs are excluded from this public checkpoint.

## Checks and unresolved work

The build completed with warnings treated as errors. Offline assertions
checked the descriptor delta, preserved ranges, actual FMAP, erased cache,
identity fields, MSDM checksum/contents, payload contents, original archives
and FSP inputs/relocation. The actual identity adapter passed valid/missing/
corrupt/truncated/unterminated-record tests under ASan/UBSan. Linked symbols
confirmed it was included and the disabled UART helpers were absent.
ME Analyzer reported valid FTPR/NFTP/ISHC signatures and partition hashes,
42 valid module-hash result lines and 56 valid MFS CRC result lines.
These do not establish keyed authentication, hardware trust-anchor linkage,
complete hardware health or complete compatibility.

Important unresolved donor assumptions include the GPIO pad table, SPD
addresses and DQ/Vref routing settings, T480 EC/PMH7 transactions, graphics
VBT/routing and USB/PCIe/dock mappings. The 940MX enable option defaults off;
its sequencing is unverified, as is the physical effect of donor GPIOs.
Old EC code contains unbounded waits. SPI console logging is disabled;
CBMEM logs can become available after memory initialization. The next useful
capture is a booted OS's CBMEM console, PCI, runtime DMI/ACPI and memory-test
results, with explicit testing of both internal display and HDMI paths.

At the time this note was first written, the programmer had been moved to the
separate failed T480 motherboard. It was subsequently reconnected to the
ThinkPad 25 for the approved stock restore below; that restore is now complete.

## Firsthand test leads

- [T470 report using Libreboot 25.06 T480 build](https://lemmy.ml/post/42078157):
  seventh-generation model, with reported audio/USB-C limitations.
- [T470 report using a mildly modified T480 port](https://www.reddit.com/r/thinkpad/comments/1vi2oi1/some_questions_about_libreboot_a_t480s/):
  exact modification diff not located; reported Thunderbolt failure.
- [Libreboot 25.06 release](https://libreboot.org/news/libreboot2506.html).

No generic flash-ready image, automatic writer, or working/daily-use port
claim is published here. Any future write needs its own reviewed image,
physical setup confirmation, exact approval and verified rollback plan.

## Post-restore status

On 2026-10-24, the user approved restoration of
`thinkpad25_bios_3.bin` (16,777,216 bytes; SHA-256
`041c88ad324f5984b0f5c9a88c75ea188e4022b71c5c586b9e6e929dc0248f0c`).
Flashrom identified the Winbond 16 MiB part and reported `VERIFIED`. Two
separate post-write reads match the image byte-for-byte and have the same
SHA-256. The original backup files were not modified. The write and readback
logs are under `logs/thinkpad25-stock-restore-20261024.log` and
`logs/thinkpad25-stock-restored-readback-{1,2}.txt` in the investigation
directory.

The next diagnostic is a stock-firmware boot using the same internal drive.
That result is pending. Keep the earlier Libreboot symptom classified as a
likely disk-GRUB startup hang because the photographed SeaBIOS countdown went
to “Booting from Hard Disk” immediately before GRUB text; it does not prove
that the separate built-in `Payload [grub2]` entry was selected or tested.

### SeaBIOS boot-order artifact comparison

Read-only `cbfstool print` inspection of the saved artifacts confirms that
the previously installed `thinkpad25-libreboot2506-experimental.rom`
(SHA-256 `42051825518a236c48165f11c6d226097a557a70b9a5b34fc04816be4bcdc8b9`)
contains `img/grub2` but no CBFS `bootorder` file. The separate
`thinkpad25-libreboot2506-grub2-default.rom`
(SHA-256 `fd96e8a6c68d3894b860ae46081f2b7e01f33c804962eab305802b1b52005738`)
contains a 15-byte `bootorder` file whose contents are `/rom@img/grub2\n`.
The two 16 MiB artifacts differ in 58 bytes across four ranges:
`0x99BD8A–0x99BD8F`, `0x99BD97–0x99BDB2`, `0x99BDC0–0x99BDCB`, and
`0x99BDD0–0x99BDDB`. This establishes the metadata change in the candidate,
not that the candidate was flashed or that its built-in GRUB payload works
on the machine. Therefore, the photographed hard-disk GRUB freeze did not
test that candidate's default-to-built-in-GRUB behavior.

The saved `t480_vfsp_16mb/target.cfg` sets both `payload_seabios="y"` and
`payload_grub="y"`, plus `grub_scan_disk="nvme ahci"`. CBFS lists
`fallback/payload` (the SeaBIOS payload) and `img/grub2` as separate entries.
The `grub_scan_disk` setting describes devices scanned by the built-in GRUB
payload; it does not configure the SeaBIOS hard-disk boot or the GRUB
installation on the internal drive. Combined with the photographed
SeaBIOS-to-hard-disk handoff, this makes a disk bootloader/legacy-boot-path
hang the best-supported explanation for that particular freeze. The exact
cause remains unknown because neither the selected entry nor the disk's GRUB
mode was recorded.

The user reports the stock-firmware comparison has not yet been performed.
When it is, record which firmware boot entry was used and whether the stock
setup is booting in UEFI or Legacy mode. A successful stock UEFI boot would
show that the drive and OS work through that UEFI path, but would not by
itself validate SeaBIOS's legacy boot path. Do not change firmware settings
just to make the comparison; record the existing mode.
