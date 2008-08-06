\ Dump a bunch of MSR values
: nn
   safe-parse-word $number abort" bad number"
;
: msrloop
   bounds ?do
      i u. i rdmsr 11 ud.r cr
   loop
;
: t
   cr nn dup 8 u.r nn dup 4 u.r ."  msrloop" cr msrloop
;

.( LX R/W MSRs) cr

\ msr ranges:
T 1000.2001 5
T 1000.0020 d
T 1000.0080 7
T 1000.008c 2
T 1000.00a1 2
T 1000.00a5 2
T 1000.00a9 2
T 1000.00ad 2
T 1000.00c0 8
T 1000.00d0 10
T 1000.00e0 9

T 4000.2001 5
T 4000.0020 f
T 4000.0080 7
T 4000.008c 2
T 4000.00a1 2
T 4000.00a5 2
T 4000.00a9 2
T 4000.00ad 2
T 4000.00c0 8
T 4000.00d0 10
T 4000.00e0 9

T 0000.2001 5

\ 0000.0010 1 \ TSC
\ 0000.00c1 2 \ perf event ctrs
\ 0000.0174 3 \ cs, ss, sip
\ 0000.0186 2 \ perf event ctr ctl

T 0000.1100 1 \ instruction fetch configuration
\ T 0000.1108 5 \ btb test

T 0000.1210 2 \ exception configuration and mode
T 0000.1250 1 \ ID configuration

T 0000.1301 2 \ SMM and DMI

T 0000.1700 1 \ IM config !!
T 0000.1800 1 \ DM config !!
T 0000.1801 1 \ DM config !!
T 0000.1804 1 \ DM config !!
T 0000.1808 1  \ def Region config
T 0000.180a e  \ Region configs 

\ A bunch of cache and tlb stuff

T 0000.1900 2  \ bus controller configs

\ 0000.1908 1  \ msr lock
\ 0000.1910 1  \ real time stamp counter
\ 0000.1911 1  \ TSC low dwords

T 0000.1920 1  \ L2 cache config !!
T 0000.1927 1  \ L2 cache treatment control !!
T 0000.1930 1  \ Power mode !!

T 0000.1980 4  \ memory subsystem array

T 0000.1a00 1  \ FPU modes
\ A bunch of FPU stuff

\ A bunch of CPUID stuff

\ -- Memory controller

T 2000.2002 4

T 2000.0018 3
T 2000.001c 2
T 2000.0020 1

\ GP

T a000.2001 5

\ -- DC

T 8000.2001 5
T 8000.0012 1 \ DC RAM Control

\ -- VP

T 4800.2001 5

T 4800.0010 2 \ VP Diagnostic and Pad Select

\ GLCP

T 4c00.2001 5

T 4c00.0008 2
T 4c00.000b 2
\ 4c00.000d has status bits that can't be set directly
T 4c00.000e 3
T 4c00.0012 5

T 4c00.0018 1 \ Clock throttling
\ 4c00.0019   Reading this register causes entry to C2 state!
T 4c00.001c 3 \ Throttle control
\ T 4c00.0023 1 \ Debug interface
T 4c00.0031 1 \ A20M !!
T 4c00.0033 1 \ CPU INIT !!

\ -- GLPCI

T 5000.2001 5

T 5000.2010 11


\ 5536
.( 5536 MSRs) cr

\ -- MBSB

T 5101.0000 6  \ Responds to 5101.2000 6 too
T 5101.0020 7
T 5101.0080 d
T 5101.00a0 b
T 5101.00c0 2
T 5101.00d0 4
T 5101.00e0 12

\ -- GLPCI_SB

T 5100.0000 6
T 5100.0010 1
T 5100.0020 15

T 5150.0000 6

\ AC natives:  0 80

\ -- USB

T 5120.0000 6
T 5120.0008 4

\ USB natives - OHC - 0 64  p 258
\ USB natives - EHC - 0 a8  p 259

\ -- ATA (don't care)

T 5130.0000 6
T 5130.0008 1
T 5130.0010 6

\ ATA natives - 0 5

\ -- DIVIL (MDD)

T 5140.0000 6
T 5140.0008 2
T 5140.000b 1b
T 5140.0028 3
T 5140.0037 a
T 5140.004e 2
T 5140.0054 4

\ SMB natives 0 8
\ KEL natives 100 10  (and port 92)
\ UART natives 3f8 8 (and banks)
\ DMA natives (isa stuff)
\ RTC natives
\ GPIO natives
\ MFGPT natives (0 40)
\ ACPI natives (emulated?)
\ PM natives (emulated?)

T 5170.0000 6
T 5170.0008 9
T 5170.00012 6

0 [if]
\ some native registers 0 50  by 4
select screen
.( GP) cr
0 50 bounds ?do i u. i gp-base + l@ 9 u.r cr 4 +loop

\ DC native registers 0 90

.( DC) cr
0 90 bounds ?do i u. i dc@ 9 u.r cr 4 +loop

\ VP native registers - 0 134

.( VP) cr
ok 0 134 bounds ?do i u. i vp@ 9 u.r cr 4 +loop

\ flat panel 400 70 by 4
\ ok 400 70 bounds ?do i u. i vp@ 9 u.r cr 4 +loop
\ --- all 0 (system has no dcon) --

[then]
