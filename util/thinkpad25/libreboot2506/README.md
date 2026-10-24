# ThinkPad 25 Libreboot 25.06 experiment

This is a source/configuration checkpoint for a locally adapted T480 build
on an original ThinkPad 25 (20K7). It is not a supported ThinkPad 25 target,
a signed Libreboot release, a generic replacement ROM, or a daily-use claim.

The overlay targets coreboot c247f62749b967143e58c33aa0e5e234711a628f
**after all 42 coreboot/default patches from lbmk
c46a71138c77556b103a4a5c85917d5bb5cc915a have been applied**.
It does not target the current source tree containing this directory.
`source-pins.json` pins that baseline, dependencies and release patches.

From that separate, clean Libreboot-patched source checkout, first check
and then apply the overlay with `git apply --check PATH/thinkpad25-local-adaptations.patch`
and `git apply PATH/thinkpad25-local-adaptations.patch`.
`thinkpad25.config` is the resolved configuration actually compiled, and
`thinkpad25.fmd` is its flash layout. The relative paths in the configuration
refer to the original private assembly workspace, not this repository:

- `../configs/thinkpad25.fmd`: copy of the supplied layout;
- `../private/ifd-candidate.bin`: this board's descriptor with HAP set;
- `../private/gbe-original.bin`: this board's original GbE;
- `../private/me-candidate.bin`: donor ME reconstructed using this board's delta;
- `../release-seabios-payload.elf`: payload extracted from the verified release.

The patch adds captured-codec pin defaults, guards T480-specific UART setup,
uses a preservation layout, and supplies a bounded SMBIOS identity adapter.
It also includes a byte-equivalent GCC 15 initializer compatibility fix.
These changes alone are **not a complete image assembly recipe**. An image
also requires inserting that board's private identity record and MSDM table,
copying its original stock-data range, and inserting the release payload
companions and archival originals. Those private inputs and assembled images
are deliberately not published. Do not substitute another board's dump.

The identity CBFS record `thinkpad25/identity` consists of eight bytes
`T25ID001`, the 16 raw UUID bytes from captured SMBIOS type 1, and ten
NUL-terminated, zero-padded 128-byte strings: system serial, board serial,
chassis serial, board asset tag, system SKU, system version, board version,
chassis version, system product, board product. The source contains no
machine identifiers. `fallback/slic` contains the original MSDM ACPI table.

See [the experiment report](../../../Documentation/mainboard/lenovo/thinkpad25-libreboot-experiment.md)
for installation verification, observed boot milestones, preservation limits
and unresolved hardware mappings. No automatic flashing utility is included.
