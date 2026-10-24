# ThinkPad T480 SPI recovery notes

Status recorded 2026-10-24. This is a separate T480 motherboard from the
ThinkPad 25 experiment documented in `thinkpad25-libreboot-experiment.md`.

## Read-only programmer checks

The main BIOS flash is a 16 MiB Winbond W25Q128JV. The CH341A is visible to
the Ubuntu host. `flashrom -p ch341a_spi` intermittently failed to identify a
chip, but successful probes identified it as `W25Q128.V` (16384 kB).

The first new read, saved locally as
`/home/ubuntu/t480-analysis/live-reads/t480-reseat-read1.bin`, was not a
reliable dump: 16,725,310 of its 16,777,216 bytes were `0xff`, and it differed
from the recorded checkpoint post-install readback. Do not use it as a backup
or as evidence of the chip contents.

Two subsequent full reads, saved locally as `t480-reseat-read2.bin` and
`t480-reseat-read3.bin`, were each 16,777,216 bytes and matched byte for byte.
Their SHA-256 was:

```
cd45ee0d7e634190b6cfc03c9afd591c0d646bd9423cf4965073b3dbe9a39951
```

This matches both the checkpoint candidate and its saved independent
post-install readback. The read confirms the flash contents at that time; it
does not establish whether the checkpoint boot was attempted or diagnose the
original platform-reset failure. No flash contents were changed during these
read checks. The binary captures remain in the local analysis directory and
are not part of this commit.

## Next diagnostic step

If the checkpoint boot has not yet been attempted, disconnect the programmer
USB and remove the clip before powering the board. Perform one controlled boot
with normal cooling and RAM, record the visible and audible behavior, then
remove all target power before reconnecting the programmer. Take two fresh
read-only dumps and decode the reserved checkpoint area. A missing checkpoint
is ambiguous and does not by itself identify a failed component.
