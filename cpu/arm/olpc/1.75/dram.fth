\ From K4B1G04(08/16)46E datasheet:


h# d0000000 constant mem-ctrl-base
: +mem-ctrl  ( offset -- adr )  mem-ctrl-base +  ;

defer do-mem-reg  ( apf -- )
' drop to do-mem-reg

defer outbits
' noop to outbits

: mem-reg:  ( offset -- )   create ,  does> do-mem-reg ;

defer do-bits  ( startbit# #bits -- )
' 2drop to do-bits

: bits:  ( startbit# #bits -- )  create , ,  does> 2@  do-bits  ;

h#   20 mem-reg: sdram-config-type1-cs0
h#   30 mem-reg: sdram-config-type1-cs1
h#   40 mem-reg: sdram-config-type1-cs2
h# b300 mem-reg: sdram-config-type1-cs3
decimal
28 3 bits: pasr
20 2 bits: rtt_wrn
17 3 bits: rttn
14 3 bits: odsn
12 2 bits: csn-no-bank
 8 4 bits: csn-no-row
 4 4 bits: csn-no-col
hex
h#  50 mem-reg: sdram-timing1
decimal
29  3 bits: tccd
26  3 bits: trtp
22  4 bits: twtr
16  6 bits: trc
 0 16 bits: trefi
hex
h#  60 mem-reg: sdram-timing2
decimal
28  4 bits: trp
24  4 bits: trrd
20  4 bits: trcd
16  4 bits: twr
 4  9 bits: trfc
 0  3 bits: tmrd
hex
h#  80 mem-reg: sdram-ctrl1
decimal
31  1 bits: aps-en
28  3 bits: aps-type
16 12 bits: aps-value
12  3 bits: acs-exit-dly
 7  1 bits: acs-en
 6  1 bits: dll-reset
 4  1 bits: cas-bt
 3  1 bits: outen
 1  1 bits: tw2r-dis
hex
h#  90 mem-reg: sdram-ctrl2
decimal
27  1 bits: ref-posted-en
24  3 bits: ref-posted-max
16  6 bits: sdram-line-boundary
 9  1 bits: refpb-mode
 8  1 bits: pd-mode
 6  1 bits: 2t-mode
 5  1 bits: rdimm-mode
 4  1 bits: aprecharge
 1  1 bits: int-shadow-mode
 0  1 bits: test-mode
hex

h#  f0 mem-reg: sdram-ctrl3
decimal
31  1 bits: early-cmd-en
30  1 bits: mc-flop-req-en
19  1 bits: mstr3-early-write-en
18  1 bits: mstr2-early-write-en
17  1 bits: mstr3-fast-write-en
16  1 bits: mstr2-fast-write-en
 9  3 bits: sb-early-write-uservalue
 6  3 bits: cpu-early-write-uservalue
 5  1 bits: sb-early-write-user
 4  1 bits: cpu-early-write-user
 3  1 bits: sb-early-write-en
 2  1 bits: cpu-early-write-en
 1  1 bits: sb-fast-write-en
 0  1 bits: cpu-fast-write-en
hex

h# 100 mem-reg: mmap0
h# 110 mem-reg: mmap1
decimal
23  9 bits: start-addr
16  4 bits: area-length
 7  9 bits: addr-mask
 0  1 bits: cs-valid
hex

h# 120 mem-reg: user-initiated-command0
decimal
28  2 bits: user-dpd-req
24  2 bits: chip-select
14  1 bits: user-zq-reset
13  1 bits: user-zq-short
12  1 bits: user-zq-long
11  1 bits: user-lmr3-req
10  1 bits: user-lmr2-req
 9  1 bits: user-lmr1-req
 8  1 bits: user-lmr0-req
 6  2 bits: user-sr-req
 5  1 bits: user-pre-ps-req
 4  1 bits: user-act-ps-req
 0  1 bits: sdram-init-req
hex

h# 140 mem-reg: phy-ctrl3
decimal
16 16 bits: phy-res                  \ Reserved, but Marvell spreadsheet sets it
15  1 bits: phy-rfifo-rd-rst-early
14  1 bits: phy-rfifo-rd-rst-en
12  1 bits: dq-oen-extend
10  2 bits: dq-oen-dly
 7  3 bits: rd-ext-dly
 4  3 bits: phy-rfifo-rptr-dly-val
 0  4 bits: dq-ext-dly
hex

h# 180 mem-reg: cm-write-protection
decimal
0 32 bits: write-protection
hex

h# 190 mem-reg: sdram-timing3
decimal
28  4 bits: tmod
26  1 bits: txsnr-8
16 10 bits: txsrd
 8  8 bits: txsnr
 3  5 bits: txards
 0  3 bits: txp
hex

h# 1a0 mem-reg: sdram-ctrl4
decimal
31  1 bits: sdram-dll-en
30  1 bits: dqsb-en
29  1 bits: fast-bank
22  3 bits: burst-length \ 3 = BL8 for DDR3
19  3 bits: al-number    \ unsupported
18  1 bits: al-en
17  1 bits: rq-ds-en
14  3 bits: cas-latency
13  1 bits: cas-latency-lower
10  3 bits: cwl
 8  1 bits: s4-type \ LPDDR2 only
 7  1 bits: asr  \ DDR3 only
 6  1 bits: srt  \ DDR3 only
 5  1 bits: mpr  \ DDR3 only
 2  3 bits: sdram-type  \ 2 = DDR3
 0  2 bits: data-width
hex

h# 1b0 mem-reg: dram-status

h# 1c0 mem-reg: sdram-timing4
decimal
28  2 bits: tcke
20  8 bits: init-count
17  3 bits: trwd-ext-dly
10  7 bits: reset-count
0  10 bits: init-count-nop
hex

h# 1d0 mem-reg: phy-ctrl7
decimal
28  2 bits: phy-qs-vref-sel
24  4 bits: phy-dq-zpdrv
20  4 bits: phy-dq-zndrv
16  4 bits: phy-dq-zptrm
12  4 bits: phy-dq-zntrm
 8  4 bits: phy-dq-znr
 4  4 bits: phy-dq-zpr
 2  2 bits: phy-dq-vref-sel
 1  1 bits: phy-dq-zd
 0  1 bits: phy-dq-mode
hex

h# 1e0 mem-reg: phy-ctrl8
decimal
24  4 bits: phy-adcm-zpdrv
20  4 bits: phy-adcm-zndrv
16  4 bits: phy-adcm-zptrm
12  4 bits: phy-adcm-zntrm
 8  4 bits: phy-adcm-znr
 4  4 bits: phy-adcm-zpr
 1  1 bits: phy-adcm-zd
hex

h# 1f0 mem-reg: phy-ctrl9
decimal
31  1 bits: phy-dq-rc-vtype
30  1 bits: phy-qs-rc-vtype
27  3 bits: phy-dq-rc-vep
24  3 bits: phy-dq-rc-ven
21  1 bits: phy-ck-zd
17  3 bits: phy-wck-ds-dly
14  3 bits: phy-wc-qs-dly
11  3 bits: phy-wck-ac-dly
 8  3 bits: phy-wck-ck-dly
 4  4 bits: phy-ck-znr
 0  4 bits: phy-ck-zpr
hex

h# 200 mem-reg: phy-ctrl10
decimal
20  2 bits: pad-cal-interval
17  3 bits: pad-cal-auto-sel
16  1 bits: pad-cal-auto
12  2 bits: read-fifo-depth
10  1 bits: write-dqsb-one
 9  1 bits: ext-req-phy-sync-dis
 8  1 bits: write-dqsb-en
 4  1 bits: mc-qsn-pd
 3  1 bits: mc-qsp-pd
 2  1 bits: mc-dq-pd
 1  1 bits: mc-ck-pd
 0  1 bits: mc-ac-d
hex

h# 210 mem-reg: phy-ctrl11
decimal
 0  1 bits: mc-sync-type
hex

h# 230 mem-reg: phy-ctrl13
decimal
28  4 bits: dll-resrt-timer
27  1 bits: dll-update-stall-mc-dis
16  9 bits: dll-delay-test
 4  5 bits: dll-phsel
 3  1 bits: dll-auto-manual-up
 2  1 bits: dll-auto-update-en
 1  1 bits: dll-test-en
 0  1 bits: dll-bypass-en
hex

h# 240 mem-reg: phy-ctrl14
decimal
31  1 bits: phy-sync-en
30  1 bits: dll-update-en
29  1 bits: phy-dll-rst
28  1 bits: phy-pll-rst
27  1 bits: dll-update-en-static
20  4 bits: phy-cal-zpr
16  4 bits: phy-cal-znr
 8  8 bits: dll-delay-out
 5  1 bits: dll-clk-tst
 1  1 bits: pll-pin-tst
 0  1 bits: pll-pll-lock
hex

h# 280 mem-reg: sdram-ctrl5-arb-weights
decimal
24  4 bits: master-3-weight
16  4 bits: master-2-weight
 8  4 bits: master-1-weight
 0  4 bits: master-0-weight
hex

\ h# 2c0 mem-reg: sys
\ h# 380 mem-reg: exclusive-monitor-ctrl
h# 3b0 mem-reg: trustzone-sel
decimal
31  1 bits: tz-lock
 0  2 bits: tz-reg-sel
hex

h# 3c0 mem-reg: trustzone-range0
decimal
20 12 bits: tz-range1
 4 12 bits: tz-range0
hex

h# 3d0 mem-reg: trustzone-range1
decimal
20 12 bits: tz-range3
 4 12 bits: tz-range2
hex

h# 3e0 mem-reg: trustzone-permission
decimal
31  1 bits: tz-enable
12  3 bits: tzact-ru
 9  3 bits: tzact-r3
 6  3 bits: tzact-r2
 3  3 bits: tzact-r1
 0  3 bits: tzact-r0
hex

h# 410 mem-reg: user-initiated-command1
decimal
24  2 bits: chip-select
17  1 bits: mrw  \ LPDDR2 only
16  1 bits: mrr  \ LPDDR2 only
 0  8 bits: addr \ LPDDR2 only
hex

h# 440 mem-reg: mode-rd-data
decimal
\ 0  8 bits: mrr-data  \ LPDDR2 only
hex

h# 490 mem-reg: error-id
decimal
31  1 bits: error-oor
30  1 bits: error-tz
 0 12 bits: error-id
hex

h# 4a0 mem-reg: error-addr

h# 4d0 mem-reg: test-mode1
decimal
20  4 bits: csn
18  3 bits: bank-address
 0 14 bits: address
hex

h# 540 mem-reg: mcb-ctrl4
decimal
25  1 bits: mcbx-wrap-burst-en
17  1 bits: mcbx-rgerr-en
hex

h# 570 mem-reg: mcb-slfst-sel
decimal
 0  2 bits: mcbx-select
hex

h# 580 mem-reg: mcb-slfst-ctrl0
decimal
28  4 bits: mstr3-wgt-slow
24  4 bits: mstr2-wgt-slow
20  4 bits: mstr1-wgt-slow
16  4 bits: mstr0-wgt-slow
12  4 bits: mstr3-wgt-fast
 8  4 bits: mstr2-wgt-fast
 4  4 bits: mstr1-wgt-fast
 0  4 bits: mstr0-wgt-fast
hex

h# 590 mem-reg: mcb-slfst-ctrl1
decimal
\ 29 3 bits: reserved
28 1 bits: page-timeout-en-stage2
24 4 bits: page-timeout-val-stage2
20 4 bits: page-timeout-val-slow
16 4 bits: page-timeout-val-fast
15 1 bits: page-timeout-en-slow
14 1 bits: page-timeout-en-fast
13 1 bits: wrr-en-slow
12 1 bits: page-en-slow
11 1 bits: wrr-en-fast
10 1 bits: page-en-fast
9 1 bits: wrr-en-stage2
8 1 bits: page-en-stage2
4 4 bits: slow-wgt-stage2
0 4 bits: fast-wgt-stage2
hex

h# 5a0 mem-reg: mcb-slfst-ctrl2
decimal
\ 20 12 bits: reserved
19 1 bits: priority-stage2
18 1 bits: priority-en-stage2
17 1 bits: priority-en-slow
16 1 bits: priority-en-fast
14 2 bits: priority-slow-1st
12 2 bits: priority-slow-2nd
10 2 bits: priority-slow-3rd
8 2 bits: priority-slow-4th
6 2 bits: priority-fast-1st
4 2 bits: priority-fast-2nd
2 2 bits: priority-fast-3rd
0 2 bits: priority-fast-4th
hex

h# 5b0 mem-reg: mcb-slfst-ctrl3
decimal
\ 8 24 bits: reserved
7 1 bits: mstr3-slow-half
6 1 bits: mstr2-slow-half
5 1 bits: mstr1-slow-half
4 1 bits: mstr0-slow-half
3 1 bits: mstr3-fast-half
2 1 bits: mstr2-fast-half
1 1 bits: mstr1-fast-half
0 1 bits: mstr0-fast-half
hex

h# 650 mem-reg: sdram-timing5
decimal
16  6 bits: tras
 4  6 bits: tfaw
 0  3 bits: tccd-ccs-ext-dly
hex

h# 660 mem-reg: sdram-timing6
decimal
20  9 bits: tzqcs
10  9 bits: tzqoper
 0  9 bits: tzqinit
hex

h# 760 mem-reg: sdram-ctrl6-odt-ctrl
decimal
12  4 bits: odt1-read-en
 8  4 bits: odt1-write-en
 4  4 bits: odt0-read-en
 0  4 bits: odt0-write-en
hex

h# 770 mem-reg: sdram-ctrl7-odt-ctrl2
decimal
24  2 bits: pad-term-switch-mode
 2  2 bits: odt1-switch-mode
 0  2 bits: odt0-switch-mode
hex

h# 780 mem-reg: sdram-ctrl8-odt-ctrl2
decimal
 8  1 bits: xpage-en
 4  4 bits: mc-queue-size-f
 0  4 bits: mc-queue-size
hex

h# 7b0 mem-reg: sdram-ctrl11-arb-weights-fast-queue
decimal
24  4 bits: master-3-weight-f
16  4 bits: master-2-weight-f
 8  4 bits: master-1-weight-f
 0  4 bits: master-0-weight-f
hex

h# 7d0 mem-reg: sdram-ctrl13
decimal
 0  4 bits: mstr-wrap-en
hex

h# 7e0 mem-reg: sdram-ctrl14
decimal
 0  1 bits: block-all-data-requests
hex

h# b40 mem-reg: sdram-config-type2-cs0
decimal
 8  8 bits: segment-mask
 0  8 bits: bank-mask
hex

h# b50 mem-reg: sdram-config-type2-cs1
decimal
\ 8  8 bits: segment-mask
\ 0  8 bits: bank-mask
hex

h# c00 mem-reg: register-table-ctrl-0
decimal
31  1 bits: regtable-write
 5  2 bits: regtable-sel
 0  5 bits: regtable-addr
hex

h# c20 mem-reg: register-table-data-0
h# c30 mem-reg: register-table-data-1
decimal
12  1 bits: regtable-eop
 0 11 bits: regtable-reg-off
hex

h# e10 mem-reg: phy-dll-ctrl1
decimal
16  9 bits: dll-delay-test
 4  5 bits: dll-phsel
 2  1 bits: dll-auto-update-en
 1  1 bits: dll-test-en
 0  1 bits: dll-bypass-en
hex

h# e20 mem-reg: phy-dll-ctrl2
\ same
h# e30 mem-reg: phy-dll-ctrl3
\ same

h# e40 mem-reg: phy-ctrl-wl-select
decimal
16 1 bits: phy-wl-dqs-recen-dqs
 8 4 bits: phy-wl-cs-sel
 0 4 bits: phy-wl-byte-sel
hex

h# e50 mem-reg: phy-ctrl-wl-ctrl0
decimal
16 7 bits: phy-wl-wck-qs-dly
 0 7 bits: phy-wl-wck-dq-dly
hex

h# e80 mem-reg: phy-ctrl-testmode
decimal
\  4  1 bits: phy-si
\  3  1 bits: phy-tms
\  2  1 bits: phy-tdoe
\  1  1 bits: phy-se
\  0  1 bits: phy-ase
hex

h# f00 mem-reg: performance-counter-ctrl-0
decimal
12  4 bits: pc-int-en-clear
 8  4 bits: pc-int-en-set
 4  4 bits: pc-reg-en-clear
 0  4 bits: pc-reg-en-set
hex

h# f10 mem-reg: performance-counter-ctrl-1
decimal
16  3 bits: pc-clk-div
 4  4 bits: pc-stop-cond
 0  4 bits: pc-start-cond
hex

h# f20 mem-reg: performance-counter-status
decimal
16  3 bits: pc-ovrflow
 8  4 bits: pc-int-en
 0  4 bits: pc-reg-en
hex

h# f40 mem-reg: performance-counter-select
decimal
31  1 bits: pc-event-update
 8  5 bits: pc-event-sel
 0  4 bits: pc-reg-sel
hex

h# f50 mem-reg: performance-counter
\ 32 bits - pc-counter

\ 1. SDRAM Config Reg Type 1 (for the one chip select)
\     If ODT: program RTT values
\ 
\ Registers: d0000020, d0000030
\ Elpida 512m: 6420, 6420   RTTn 000  ODS 001 NO_BANK 10 (8) . NO_ROW 4 (14) . NO_COL 2 (9) . 0
\ Micron 256m: 6320, 6320   RTTn 000  ODS 001 NO_BANK 10 (8) . NO_ROW 3 (13) . NO_COL 2 (9) . 0
\ Samsung  1g: 6430, 6430   RTTn 000  ODS 001 NO_BANK 10 (8) . NO_ROW 4 (14) . NO_COL 3 (10) . 0
\ 
\ Type 2: d0000b40, d0000b50: 0  (LPDDR2 only)
\ 
\ 2. Program 6 timing registers according to RAM timings
\ 
\ Register d000.0050 timing 1
\ Elpida 512m: 488700C5 tCCD 010  tRTP 010  tWTR 0010  tRC 7  tREFI c5 (197)  (tRC=7=17.5nS tREFI=197=492.5nS)
\ Micron 256m: 488600C5 tCCD 010  tRTP 010  tWTR 0010  tRC 6  tREFI c5 (197)  (tRC=6=15nS tREFI=197=492.5nS)
\ Samsung  1g:         *tCCD   4 *tRTP   4 *tWTR    4 *tRC 50.6ns   tREFI    (197)  (tRC=6=15nS tREFI=197=492.5nS)
\ 
\ Register d000.0060 timing 2
\ Elpida 512m: 323300d2 tRP 3  tRRD 2  tRCD 3  tWR 3  tRFC 0d  tMRD 2
\ Micron 256m: 323300d2 tRP 3  tRRD 2  tRCD 3  tWR 3  tRFC 0d  tMRD 2
\ Samsung  1g:         *tRP 7! *tRRD 4  *tRCD 7!  *tWR 8!  *tRFC 0x3b! (59)  tMRD 4  ! - for tCK=1.875 - 533 MHz
\ 
\ Register d000.0190 timing 3
\ Elpida 512m: 20000e12  tMOD 2 tXSRD 0 tXSNR 0e  tXARDS 00010 tXP 2 
\ Micron 256m: 20000e12  tMOD 2 tXSRD 0 tXSNR 0e  tXARDS 00010 tXP 2 
\ Samsung  1g:  *tMOD 0c  *tXSRD 0x200  *tXSNR 0x40   ,tXARDS 7  *tXP 4 
\ 
\ Register d000.01c0 timing 4
\ Elpida 512m: 3023009d  tCKE 3  INIT_COUNT 02  TRWD_EXT_DLY 001  RESET_COUNT 00  INIT_COUNT_NOP 9d
\ Micron 256m: 3023009d  tCKE 3  INIT_COUNT 02  TRWD_EXT_DLY 001  RESET_COUNT 00  INIT_COUNT_NOP 9d
\ Samsung  1g:          *tCKE 3  INIT_COUNT  ?  TRWD_EXT_DLY   ?  RESET_COUNT  ?  INIT_COUNT_NOP  ?
\ 
\ Register d000.0650 timing 5
\ Elpida 512m: 00050082  tRAS 5  tFAW 8  tCCD_CCS_EXT_DLY 2
\ Micron 256m: 00050082  tRAS 5  tFAW 8  tCCD_CCS_EXT_DLY 2
\ Samsung  1g:          *tRAS 0x14!  *tFAW 0x14!  ,tCCD_CCS_EXT_DLY 1
\ 
\ Register d000.0660 timing 6
\ Elpida 512m: 00909064 tZQCS 9  tZQOPER 0.0010.0100  tZQINIT 64
\ Micron 256m: 00909064 tZQCS 9  tZQOPER 0.0010.0100  tZQINIT 64
\ Samsung  1g:          *tZQCS 0x40 *tZQOPER 0x100  *tZQINIT 0x200
\ 
\ 3. SDRAM Control Reg 4   (other control registers are non-essential)
\ 
\ 4. If ODT: SDRAM Control Reg 6  and SDRAM Control Reg 7  (only enable ODT# with writing to CS#)
\ 
\ 5. PHY control reg values must be calibrated with scope
\ 
\ 6. Memory Address Map Register for CS0#   - then NOPs for decoder to settle
\    Configuration Register Decode Address  - then NOPs
\ 
\ 7. Write 1 to User Initiated Command Reg 0
\    Read DRAM Status Register until init done status is seen
\ 
\    (now can do data access)
\ 
\ 8. Other registers are optional - but some of them must be done before step 7
