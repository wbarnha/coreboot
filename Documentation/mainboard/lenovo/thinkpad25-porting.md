# ThinkPad 25 porting notes

## Status

This is a development baseline for the original ThinkPad 25 (20K7).
No ThinkPad 25 mainboard target, GPIO map, working ROM, or installation
procedure is implemented by these notes. The existing T470s target is a
separate board. A T480 or T470s image must not be treated as a ThinkPad 25
image on the basis of a shared processor family.

The baseline below comes from stock-firmware Linux inventories and exported
ACPI tables. It is not a full SPI backup or a hardware validation result
for coreboot.

## Observed stock configuration

| Item | Reported value |
| --- | --- |
| Machine type/model | 20K70004US, ThinkPad 25 |
| CPU | Intel Core i7-7500U |
| Memory | One dual-rank 16 GiB DDR4 module, 2133 MT/s, ChannelA-DIMM0 |
| Integrated graphics | Intel HD Graphics 620, `8086:5916` |
| Discrete graphics | NVIDIA GM108M / GeForce 940MX, `10de:134d` |
| LPC controller | Intel Sunrise Point-LP, `8086:9d58` |
| HECI | Intel Sunrise Point-LP, `8086:9d3a` |
| Ethernet | Intel I219-V, `8086:15d8` |
| HDA codec | Realtek ALC298, `10ec:0298`, subsystem `17aa:2245` |
| Vendor BIOS | N1QET94W, version 1.69, dated 2021-11-17 |
| SMBIOS EC release | 1.36 |
| SMBIOS ROM size | 16 MB; physical chip identity/capacity unverified |

The SMBIOS runtime BIOS size of 128 kB is a different field from ROM size.
Neither field replaces physical chip identification. The reported EC
release does not verify the contents of a separate EC flash.

Lenovo distributes the N1QUJ35W package for both the T470 and ThinkPad 25,
with BIOS N1QET94W and EC N1QHT54W / 1.36. This provides a reason to
investigate a T470-based port, rather than assume compatibility with the
T470s or T480:

- [Lenovo BIOS/EC release listing](https://support.lenovo.com/ag/en/downloads/ds120429-bios-update-utility-bootable-cd-for-windows-10-81-64-bit-7-32-bit-64-bit-linux-thinkpad-25-t470)

## Existing T470 testing

A tester reports running coreboot on both T470 and T480 in the
[comment linked from change 93200](https://review.coreboot.org/c/coreboot/+/93200/comments/249d783b_8ac718fc).
The June 2026 report concerns ACPI charge behavior: with two batteries,
forcing battery 0 to discharge returns an I/O error and discharges battery
1 instead. It is evidence of an experimental T470 setup, not a ThinkPad 25
validation result.

Change 93200 itself is an ACPI charge-behavior test across existing Lenovo
boards. It does not add a T470 mainboard target or provide the tester's
board-specific source changes. It should not be cherry-picked as though
it were a T470 port. The actual T470 source baseline still needs to be
located and audited before adaptation to ThinkPad 25.

## ACPI evidence

The collected stock tables contain 39 ACPI objects, with matching declared
lengths and valid applicable checksums. FACS does not have the normal
ACPI table checksum.

The DSDT declares:

- EC device `\_SB.PCI0.LPCB.EC`, with HID `PNP0C09`.
- Data/command I/O resources at `0x62` and `0x66`.
- EC `_GPE` value `0x16`.
- `ECOR`, an EmbeddedControl operation region covering offsets `0x00` to
  `0xff`.

These are firmware declarations, not an identification of the physical
EC controller or permission to probe registers. Combined disassembly
encounters duplicate namespace objects among the exported SSDTs. Isolated
disassembly has unresolved external methods. The resulting ASL must not
be copied wholesale into a port or treated as a validated namespace.

No usable panel EDID was captured in the initial inventory. Panel routing,
GPIOs, and EC/classic-keyboard behavior remain to be established.

## Read-only inventory collection

Run the collector on the original ThinkPad 25 while it is running stock
firmware:

```sh
sudo bash util/thinkpad25/collect_inventory.sh
```

The collector checks for a `20K7` DMI product before doing any collection.
It writes a new private inventory directory and `.tar.gz` archive in the
current directory. It gathers DMI, CPU, PCI, USB, raw ACPI tables, display
EDID/status, and HDA codec information. Raw ACPI collection does not
require `acpidump`; absent optional tools are recorded.

It does not invoke flashrom, install packages, execute ACPI methods, or
write SPI, EC, GPIO, PCI configuration, MSRs, TPM state, or firmware
variables. It is not an SPI-backup utility.

The output can contain serial numbers, UUIDs, MAC addresses and Windows
licensing tables. Keep it private and do not commit the archive, extracted
inventories, raw ACPI/SMBIOS data, or firmware binaries. Matching root-level
collector output names are ignored by git. No such artifacts are included
in this development baseline.

## Before implementation or installation

- Identify the physical PCB revision and main BIOS flash marking/location.
- Before external chip access, establish complete target power isolation
  and suitable supply and signal voltages for the identified flash.
- Obtain reproducible full original reads with hashes and independently
  reconnected clips, preserving unmodified backups and machine data.
- Establish this board's descriptor layout, ME SKU/configuration and Boot
  Guard policy. Processor-family support in deguard is not a completed
  board port; do not reuse another machine's ME delta or GbE data.
- Audit board-specific memory/SPD, GPIO, classic keyboard/EC, graphics,
  power/thermal, batteries, docking, and sleep/wake configuration against
  reliable evidence.
- For a future image, document exact size/hash, changed ranges, preserved
  machine data, runtime writes, verification and rollback before flashing.

No flash-ready ThinkPad 25 image is provided here. This document is not
an entry in the supported-board list.
