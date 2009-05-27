\ UMARamSetting.c
\  SetUMARam
   0 3 devfunc
 \ 99 ff 73 mreg \ 61 res be like Phx
   a1 00 80 mreg \ Enable internal GFX
   a2 ff ee mreg \ Set GFX timers
   a4 ff 01 mreg \ GFX Data Delay to Sync with Clock
   a6 ff 76 mreg \ Page register life timer
   a7 ff 8c mreg \ Internal GFX allocation
   b3 ff 9a mreg \ Disable read past write
\  de ff 06 mreg \ Enable CHA and CHB merge mode (but description says this value disable merging!) 00 for compatibility
   end-table

\   0 3 devfunc
\   a1 70 40 mreg \ Set frame buffer size to 64M (8M:10, 16M:20, 32M:30, etc) - fbsize
\   end-table

   1 0 devfunc
                 \ Reg 1b2 controls the number of writable bits in the BAR at 810
   b2 ff 70 mreg \ Offset of frame buffer, depends on size - fbsize
   04 ff 07 mreg \ Enable IO and memory access to display
   end-table

   d000.0000 810 config-wl  \ S.L. Base address
   f000.0000 814 config-wl  \ MMIO Base address
        cd01 3a0 config-ww  \ Set frame buffer size and CPU-relative address and enable

   0 0 devfunc
   c6 02 02 mreg \ Enable MDA forwarding (not in coreboot)
   d4 00 03 mreg \ Enable MMIO and S.L. access in Host Control device
   fe 00 10 mreg \ 16-bit I/O port decoding for VGA (no aliases)
   end-table

   1 0 devfunc
   b0 07 03 mreg \ VGA memory selection (coreboot uses 03, Phoenix 01.  I think 03 is correct)
   end-table

   01 3c3 port-wb                  \ Graphics chip IO port access on
   10 3c4 port-wb  01 3c5 port-wb  \ Turn off register protection
   67 3c2 port-wb                  \ Enable CPU Display Memory access (2), use color not mono port (1)

   68 3c4 port-wb  e0 3c5 port-wb  \ Size of System Local Frame Buffer - Value depends on frame buffer size - fbsize
                                   \ 00:512MB 80:256MB c0:128MB e0:64MB f0:32MB f8:16MB fc:8MB fe:4MB ff:2MB

   \ These 2 are scratch registers that communicate with the VGA BIOS
   3d 3d4 port-wb  74 3d5 port-wb  \ Value depends on DIMM frequency - used by VGA BIOS
   39 3c4 port-wb  10 3c5 port-wb  \ BIOS Reserved Register 0 - FBsize_MiB/4 - fbsize - VGA BIOS

   5a 3c4 port-wb  01 3c5 port-wb  \ Point to secondary registers
   4c 3c4 port-wb  83 3c5 port-wb  \ LCDCK Clock Synthesizer Value 2
   5a 3c4 port-wb  00 3c5 port-wb  \ Point back to primary registers

   6d 3c4 port-wb  e0 3c5 port-wb  \ Base address [28:21] of SL in System Memory - base is 1c00.0000 - fbsize, memsize
   6e 3c4 port-wb  00 3c5 port-wb  \ Base address [36:29] of SL in System Memory
   6f 3c4 port-wb  00 3c5 port-wb  \ Base address [47:37] of SL in System Memory

   36 3c4 port-wb  11 3c5 port-wb  \ Subsystem Vendor ID 1
   35 3c4 port-wb  06 3c5 port-wb  \ Subsystem Vendor ID 0
   38 3c4 port-wb  51 3c5 port-wb  \ Subsystem ID 1
   37 3c4 port-wb  22 3c5 port-wb  \ Subsystem ID 0

   f3 3c4 port-wb  00 3c5 port-wb  \ 1a for snapshot mode
   f3 3d4 port-wb  12 3c5 port-wb  \ Snapshot mode control - 1a for snapshot mode
