
: /roundup  ( num den -- quot )  /mod  swap if 1+ then  ;

: ns>clk  ( ps -- clk )  \ Assumes 400 MHz clock
   4* d# 2.500 /  4 /roundup
;

\ From K4B1G04(08/16)46E datasheet:
\ Using 08 version  -HCF8  (128Mb*8)
\ 
\ 8 banks
\ Bank Address BA0-BA2
\ Auto Precharge  A10/AP
\ Row Address A0-A13 (14 bits)
\ Column Address A0-A9  (10 col bits)
\ BC switch on the fly  A12/_BC
\ Page size 1KB
\ Burst length 8
\ 
\ === DDR3-800 speed bin - HCF7 ===
\ 6-6-6 timing
\ tAA 15-20 ns
\ tRCD min 15 ns
\ tRP min 15 ns
\ tRAS 37.5 - 9*tREFI ns
\ tRC min 52.5
\ CL 6 CK
\ CWL 5 CK
\ tCK(AVG) (for CL=6/CWL=5) 2.5-3.3 ns
\ 
\ 15 / 6 = 2.5   (400 MHz clock)
\ 20 / 6 = 3.3   (300 Mhz clock)
\ 
\ === DDR3-1066 speed bin - HCF8 ===
\ 
\ 7-7-7 timing
\ tAA 13.125 - 20 ns
\ tCK min 1.875  (533 MHz)
\ .*tRCD min 13.125 ns 
\ .*tRP min 13.125 ns
\ .*tRAS 37.5
\ .*tRC min 50.625 ns
\ .CL 7 CK
\ .CWL 6 CK
\ tCK(AVG) (for CL=7/CWL=6) 1.875-<2.5 ns
\ .tREFI 7.8 uS
\ 
\ 13.125 / 7 = 1.875   (533 MHz clock)
\ 
\ (also works with CL8/CWL6 and CL6/CWL5)
\ 29F8G08ABABA
\ 
\ .*tRFC 110 nS
\ .*tRTP max(4nCLK, 7.5nS)
\ .*tWTR max(4nCLK, 7.5nS)
\ .*tWR  15 ns
\ .*tMRD 4 T
\ .*tMOD max(12nCLK, 15nS)
\ .*tCCD 4 T
\ tMPRR 1 T
\ .*tRRD 1K page max(4nCLK, 7.5nS)
\ .*tFAW 1K page 37.5 nS
\ .*tZQinit 512
\ .*tZQoper 256
\ .*tZQCS    64
\ tXPR  max(tnCK, tRFC+10nS)  120 nS     (Exit Reset from CKE HIGH to a valid command)
\ .*tXS (tXSNR)   max(5nCK, tRFC+10nS)  120nS
\ .*tXSDLL (tXSRD) 512
\ .*tXP    max(3nCK, 7.5ns)
\ .tXPDLL max(10nCK, 24ns)
\ .*tCKE   max(3nCK, 5.625ns) DDD
\ tCKESR tCKE(min) + 1tCK
\ tCKSRE max(5nCK, 10ns)
\ tCKSRX max(5nCK, 10ns)

start-dram-init

mmap0
h# 0000.0000 d# 23 rshift start-addr   
h# 4000.0000 log2 d# 16 - area-length
h# 0000.0000 d# 23 rshift addr-mask
1 cs-valid
outbits

mmap1
h# 4000.0000 d# 23 rshift start-addr
h# 4000.0000 log2 d# 16 - area-length
h# 0000.0000 d# 23 rshift addr-mask
0 cs-valid
outbits

sdram-config-type1-cs0
0 pasr
2 rtt_wrn  \ Datasheet says unsupported, but spreadsheet sets it
1 rttn
0 odsn
8 log2 1- csn-no-bank
d# 14 d# 10 - csn-no-row
d# 10     7 - csn-no-col
outbits

sdram-config-type1-cs1
0 pasr
2 rtt_wrn  \ Datasheet says unsupported, but spreadsheet sets it
1 rttn
0 odsn
8 log2 1- csn-no-bank
d# 14 d# 10 - csn-no-row
d# 10     7 - csn-no-col
outbits

\ sdram-config-type1-cs2
\ 0 pasr
\ 0 rtt_wrn  \ Datasheet says unsupported, but spreadsheet sets it
\ 0 rttn
\ 0 odsn
\ 0 ( 8 log2 1- ) csn-no-bank
\ 0 ( d# 14 d# 10 - ) csn-no-row
\ 0 ( d# 10     7 - ) csn-no-col
\ outbits
\ 
\ sdram-config-type1-cs3
\ 0 pasr
\ 0 rtt_wrn  \ Datasheet says unsupported, but spreadsheet sets it
\ 0 rttn
\ 0 odsn
\ 0 ( 8 log2 1- ) csn-no-bank
\ 0 ( d# 14 d# 10 - ) csn-no-row
\ 0 ( d# 10     7 - ) csn-no-col
\ outbits

sdram-config-type2-cs0
0 segment-mask
0 bank-mask
outbits

sdram-config-type2-cs1
0 segment-mask
0 bank-mask
outbits

sdram-timing1
4 tccd
d#    7.500 ns>clk 4 max  trtp
d#    7.500 ns>clk 4 max  twtr
d#   50.625 ns>clk trc
d# 7.8  d# 26  d# 10 */  trefi  \ 7.8 uS is the refresh interval, 26 MHz is the refresh clock rate
outbits

sdram-timing2
d#  13.125 ns>clk  0 max  trp
d#   7.500 ns>clk  4 max  trrd
d#  13.125 ns>clk  0 max  trcd
d#  15.000 ns>clk  0 max  twr
d# 110.000 ns>clk         trfc
         4                tmrd
outbits

sdram-timing3
d#  15.000 ns>clk d#  12 max tmod
         0                   txsnr-8  \ Needs checking !!!
d# 512.000 ns>clk d# 512 max txsrd
d# 120.000 ns>clk d#   5 max txsnr    \ Needs checking !!!
d#  24.000 ns>clk d#  10 max txards
d#   7.500 ns>clk d#   3 max txp
outbits

sdram-timing4
d#      5.625 ns>clk d#  4 max  tcke
d# 200000.000 ns>clk d# 1024 /roundup  init-count
            1                   trwd-ext-dly
d#    100.000 ns>clk            reset-count
d#        390                   init-count-nop
outbits

sdram-timing5
d# 37.500 ns>clk  0 max  tras
d# 37.500 ns>clk  0 max  tfaw
d#      1                tccd-ccs-ext-dly
outbits

sdram-timing6
0 d#  64 max tzqcs
0 d# 256 max tzqoper
0 d# 512 max tzqinit
outbits

sdram-ctrl1
1 aps-en
1 aps-type
4 aps-value
d# 12.500 ns>clk acs-exit-dly
0 acs-en
0 dll-reset
0 cas-bt
0 outen
0 tw2r-dis
outbits

sdram-ctrl2
0 ref-posted-en
0 ref-posted-max
d# 16 sdram-line-boundary
0 refpb-mode
0 pd-mode
0 2t-mode
0 rdimm-mode
1 aprecharge
0 int-shadow-mode
0 test-mode
outbits

sdram-ctrl3
1 early-cmd-en
1 mc-flop-req-en
0 mstr3-early-write-en
0 mstr2-early-write-en
0 mstr3-fast-write-en
0 mstr2-fast-write-en
0 sb-early-write-uservalue
0 cpu-early-write-uservalue
0 sb-early-write-user
0 cpu-early-write-user
0 sb-early-write-en
0 cpu-early-write-en
0 sb-fast-write-en
0 cpu-fast-write-en
outbits

sdram-ctrl4
0 sdram-dll-en
0 dqsb-en
1 fast-bank
3 burst-length \ 3 = BL8 for DDR3
0 al-number    \ unsupported
0 al-en
0 rq-ds-en
3 cas-latency        \ For DDR3, upper 3 bits of CL - so 3 for CL6 and CL7
0 cas-latency-lower  \ For DDR3, lower bit of CL - so 0 for CL6, 1 for CL7
1 cwl  \ 0 for WL5, 1 for WL6, 2 for WL7, 3 for WL8
0 s4-type \ LPDDR2 only
0 asr  \ DDR3 only
0 srt  \ DDR3 only
0 mpr  \ DDR3 only
2 sdram-type  \ 2 = DDR3
1 data-width  \ 0 = x16, 1 = x32
outbits

sdram-ctrl5-arb-weights
1 master-3-weight
1 master-2-weight
1 master-1-weight
1 master-0-weight
outbits

sdram-ctrl6-odt-ctrl
0 odt1-read-en
0 odt1-write-en
0 odt0-read-en
1 odt0-write-en
outbits

sdram-ctrl7-odt-ctrl2
1 pad-term-switch-mode \ Termination enabled on any read or write
0 odt1-switch-mode     \ Disabled
2 odt0-switch-mode     \ Controlled by write_en and read_en
outbits

sdram-ctrl8-odt-ctrl2
1 xpage-en
3 mc-queue-size-f
3 mc-queue-size
outbits

sdram-ctrl11-arb-weights-fast-queue
1 master-3-weight-f
1 master-2-weight-f
1 master-1-weight-f
1 master-0-weight-f
outbits

sdram-ctrl13
1 mstr-wrap-en
outbits

sdram-ctrl14
0 block-all-data-requests
outbits

mcb-ctrl4
0 mcbx-wrap-burst-en
0 mcbx-rgerr-en
outbits

mcb-slfst-sel
1 mcbx-select  \ Select MCB1
outbits

mcb-slfst-ctrl0
0 mstr3-wgt-slow
0 mstr2-wgt-slow
0 mstr1-wgt-slow
0 mstr0-wgt-slow
0 mstr3-wgt-fast
0 mstr2-wgt-fast
0 mstr1-wgt-fast
0 mstr0-wgt-fast
outbits

mcb-slfst-ctrl1
0 page-timeout-en-stage2
0 page-timeout-val-stage2
0 page-timeout-val-slow
0 page-timeout-val-fast
0 page-timeout-en-slow
0 page-timeout-en-fast
0 wrr-en-slow
0 page-en-slow
0 wrr-en-fast
0 page-en-fast
0 wrr-en-stage2
0 page-en-stage2
0 slow-wgt-stage2
0 fast-wgt-stage2
outbits

mcb-slfst-ctrl2
0 priority-stage2
0 priority-en-stage2
0 priority-en-slow
0 priority-en-fast
0 priority-slow-1st
0 priority-slow-2nd
0 priority-slow-3rd
0 priority-slow-4th
0 priority-fast-1st
0 priority-fast-2nd
0 priority-fast-3rd
0 priority-fast-4th
outbits

mcb-slfst-ctrl3
0 mstr3-slow-half
0 mstr2-slow-half
0 mstr1-slow-half
0 mstr0-slow-half
0 mstr3-fast-half
0 mstr2-fast-half
0 mstr1-fast-half
0 mstr0-fast-half
outbits

cm-write-protection
0 write-protection
outbits

phy-ctrl11
0 mc-sync-type
outbits

\ This is the base value
phy-ctrl14
1 phy-sync-en
0 dll-update-en
0 phy-dll-rst
0 phy-pll-rst
0 dll-update-en-static
outbits

\ Assert DLL reset
phy-ctrl14
1 phy-sync-en
0 dll-update-en
1 phy-dll-rst
0 phy-pll-rst
0 dll-update-en-static
outbits

\ Release DLL reset
phy-ctrl14
1 phy-sync-en
0 dll-update-en
0 phy-dll-rst
0 phy-pll-rst
0 dll-update-en-static
outbits

\ First value, with auto-cal enabled
phy-ctrl10
1 pad-cal-interval
b# 000 pad-cal-auto-sel  \ Used fixed values, not autocalibration
1 pad-cal-auto
3 read-fifo-depth
0 write-dqsb-one
0 ext-req-phy-sync-dis
1 write-dqsb-en
1 mc-qsn-pd
1 mc-qsp-pd
1 mc-dq-pd
0 mc-ck-pd
0 mc-ac-d
outbits

show-auto-cal

\ Final value, with auto-cal disabled to save power
phy-ctrl10
1 pad-cal-interval
b# 000 pad-cal-auto-sel  \ Used fixed values, not autocalibration
0 pad-cal-auto
3 read-fifo-depth
0 write-dqsb-one
0 ext-req-phy-sync-dis
1 write-dqsb-en
1 mc-qsn-pd
1 mc-qsp-pd
1 mc-dq-pd
0 mc-ck-pd
0 mc-ac-d
outbits

phy-ctrl3
h# 2000 phy-res                  \ Reserved, but Marvell spreadsheet sets it
0 phy-rfifo-rd-rst-early
1 phy-rfifo-rd-rst-en
0 dq-oen-extend
0 dq-oen-dly
0 rd-ext-dly
4 phy-rfifo-rptr-dly-val  \ Tune me !!!
4 dq-ext-dly              \ Tune me !!!
outbits

phy-ctrl7
1 phy-qs-vref-sel
b# 1111 phy-dq-zpdrv
b# 1111 phy-dq-zndrv
b# 1000 phy-dq-zptrm
b# 0100 phy-dq-zntrm
b# 1000 phy-dq-znr
b# 0100 phy-dq-zpr
b#   10 phy-dq-vref-sel
0 phy-dq-zd
1 phy-dq-mode
outbits

phy-ctrl8
b# 1111 phy-adcm-zpdrv
b# 1111 phy-adcm-zndrv
b# 0000 phy-adcm-zptrm
b# 0000 phy-adcm-zntrm
b# 1000 phy-adcm-znr
b# 0100 phy-adcm-zpr
0 phy-adcm-zd
outbits

phy-ctrl9
0 phy-dq-rc-vtype
0 phy-qs-rc-vtype
0 phy-dq-rc-vep
0 phy-dq-rc-ven
0 phy-ck-zd
0 phy-wck-ds-dly
0 phy-wc-qs-dly
0 phy-wck-ac-dly
0 phy-wck-ck-dly
b# 1000 phy-ck-znr
b# 0100 phy-ck-zpr
outbits

phy-ctrl13
2 dll-resrt-timer
0 dll-update-stall-mc-dis
d# 16 dll-delay-test
d# 08 dll-phsel
1 dll-auto-manual-up
0 dll-auto-update-en
0 dll-test-en
0 dll-bypass-en
outbits

phy-dll-ctrl1
d# 16 dll-delay-test
d#  8 dll-phsel
0 dll-auto-update-en
0 dll-test-en
0 dll-bypass-en
outbits

phy-dll-ctrl2
d# 16 dll-delay-test
d#  8 dll-phsel
0 dll-auto-update-en
0 dll-test-en
0 dll-bypass-en
outbits

phy-dll-ctrl3
d# 16 dll-delay-test
d#  8 dll-phsel
0 dll-auto-update-en
0 dll-test-en
0 dll-bypass-en
outbits

phy-ctrl-wl-select
0 phy-wl-dqs-recen-dqs
0 phy-wl-cs-sel
0 phy-wl-byte-sel
outbits

phy-ctrl-wl-ctrl0
0 phy-wl-wck-qs-dly
0 phy-wl-wck-dq-dly
outbits

\ Send init command to all chip selects at once
user-initiated-command0
b# 00 user-dpd-req
b# 01 chip-select
0 user-zq-reset
0 user-zq-short
0 user-zq-long
0 user-lmr3-req
0 user-lmr2-req
0 user-lmr1-req
0 user-lmr0-req
0 user-sr-req
0 user-pre-ps-req
0 user-act-ps-req
1 sdram-init-req
outbits

wait-dram-init

\ Send MRW MR10 (ZQ long cal) to each chip select individually
user-initiated-command0
b# 00 user-dpd-req
b# 01 chip-select
0 user-zq-reset
0 user-zq-short
1 user-zq-long
0 user-lmr3-req
0 user-lmr2-req
0 user-lmr1-req
0 user-lmr0-req
0 user-sr-req
0 user-pre-ps-req
0 user-act-ps-req
0 sdram-init-req
outbits

wait-tzqinit

\ Send MRW MR10 (ZQ long cal) to another chip select and wait if necessary

do-dummy-reads

show-dll-delay

end-dram-init
