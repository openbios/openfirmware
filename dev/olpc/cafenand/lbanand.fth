\ dev /nandflash

: sectors>bytes  ( #sectors #bytes -- )  9 lshift  ;

: lba-get-sectors  ( sector# #sectors -- true | adr false )
   tuck set-page                       ( #sectors )
   sectors>bytes  dup  h# 18 cl!       ( #bytes )
   dma-buf-pa h# 44 cl!                ( #bytes )
   0 h# 48 cl!                         ( #bytes )
   h# a000.0000 or  h# 40 cl!          ( )
   read-cmd h# 0000.0130 cmd  wait-dma ( )

   dma-buf-va false
;

: lba-write-sectors  ( adr sector# #sectors -- error? )  \ Size is fixed
   write-enable                             ( adr sector# #sectors)
   tuck set-page                            ( adr #sectors )
   sectors>bytes                            ( adr #bytes )
   dup  false dma-setup                     ( )
   h# e220.0080 h# 0000.0110 cmd wait-cmd   ( )  \ No ECC, write cmd
   wait-write-done                          ( error? )
\   dma-release
;

: read57   ( len page# offset -- adr )  read-cmd h# 157 generic-read  ;
: dummy57  ( page# offset -- )  set-page dma-off  h# e020.0000 h# 157 cmd wait-cmd  ;
: dummy-read  ( page# offset -- )  set-page dma-off  h# e000.0000 h# 120 cmd wait-cmd  ;
: pnr>bcm   ( -- )  h# fc00 0  dummy-read  ;
h# ffff value vfp-password
: set-vfp-password  ( new-password -- )
   dup >r                           ( r: new-password )
   wbsplit  vfp-password wbsplit    ( npw0 npw1 opw0 opw1 r: new-pw )
   swap >r                          ( npw0 npw1 opw1 r: new-pw opw0 )
   -rot 0 bljoin   h# 21 r> bwjoin  ( page offset  r: new-pw )
   dummy57                          ( r: new-pw
   r> to vfp-password
;
: mdp>vfp   ( -- )
   vfp-password wbsplit   ( pw0 pw1 )
   h# be rot bwjoin       ( page=pw1 offset=pw0|be )
   dummy57
;
: read-lba-id  ( -- adr )  5  0 0  h# c400.0092  0  generic-read  ;
: bcm>pnr   ( -- )  ( XXX This is a variant of the write command)  ;
: 5c@  ( adr -- d )
   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r@ 3 + c@  bljoin  r> c@
;
: le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;
: mdp-size  ( -- #sectors )  5 0 h# b0 read57 5c@  ;
: vfp-size  ( -- #sectors )  2 0 h# b5 read57 le-w@  ;
: ex-vfp-sizev ( -- param type )  2 0 h# 10b8 read57 dup 1+ c@  swap c@  ;
: ex-vfp-size  ( -- param type )  2 0 h#   b7 read57 dup 1+ c@  swap c@  ;
: set-vfp-size  ( size -- )
   wbsplit swap abort" Bad alignment for VFP size"  ( size.hi )
   ?dup  if                         ( size.hi )
      dup invert                    ( size.hi ~size.hi )
      h# ff swap 0                  ( size.hi ~size.lo ~size.hi 0 )
      bljoin  h# 22                 ( page offset )
   else                             ( )
      h# dfdf20 h# 2022             ( page offset )
   then                             ( page offset )
   dummy57
;
: set-ex-vfp-size  ( type param -- )
   over invert         ( type param /type )
   swap invert         ( type param /type /param )
   0 bljoin            ( type page# )
   h# 24 rot  bljoin   ( page# offset )
   dummy57
;

: set-protocol1  ( param -- )  0  h# a2 rot  bwjoin  dummy57  ;
: get-protocol1  ( -- param )  1 0 h# b2  read57 c@  ;
: 512-byte-transfers  ( -- )  1 set-protocol1  ;
: 2048-byte-transfers  ( -- )  4 set-protocol1  ;
: set-protocol2  ( param -- )  0  h# a3 rot  bwjoin  dummy57  ;
: get-protocol2  ( -- param )  1 0 h# b3  read57 c@  ;
: set-min-busy  ( param -- )  0  h# a4 rot  bwjoin  dummy57  ;
: get-min-busy  ( -- param )  1 0 h# b4  read57 c@  ;
: get-max-busy  ( -- read write flush )
   6 0 h# b9  read57 >r r@ le-w@  r@ 2+ le-w@  r> 4 + le-w@
;
: power-down    ( -- )  0 h# ba dummy57  ;
: power-up      ( -- )  0 h# bb dummy57  ;
: fast-writing  ( -- )  0 h# bc dummy57  ;
: slow-writing  ( -- )  0 h# bd dummy57  ;
: start-free-sectors ( -- )  0 h# 5e dummy57  ;
: free-sectors   ( sector# #sectors -- )
   set-page                                 ( )
   h# e020.0080 h# 0000.0110 cmd wait-cmd   ( )  \ No ECC, write cmd (no data transfer)
;
: end-free-sectors   ( -- )  0 h# 5f dummy57  ;
: read-attributes  ( which -- adr )
   0 h# 9e dummy57       ( which )
   d# 512 swap 1  read-cmd h# 0000.0130 generic-read  ( adr )
   0 h# 9f dummy57       ( adr )
;
: unique-id  ( -- adr )  0 read-attributes  ;
: firmware-version  ( -- adr )  h# 10 read-attributes  ;
: hardware-version  ( -- adr )  h# 20 read-attributes  ;
: cache-flush  ( -- )  h# 8020.00f9 0 cmd  wait-cmd  wait-ready  ;
: pnr-mode  ( -- )  h# 8020.00fd 0 cmd  wait-cmd  wait-ready  ;
: lba-mode  ( -- )  h# 8020.00fc 0 cmd  wait-cmd  wait-ready  ;

: setup  ( -- )
   alloc-dma-buf
   set-lmove

   h# 24 cl@ h#     ff00 invert and  h#     1000 or  h# 24 cl!
   h# 28 cl@ h# ff000000 invert and  h# f0000000 or  h# 28 cl!
   h# 7fff.ffff to chip-boundary

   lba-mode
   2 set-protocol1  \ 2048-byte max transfer size
   h# 200 to /page
;

\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the OBP external interface is byte-oriented,
\ in order to be independent of particular device block sizes.

0 instance value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  to deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;


\ Label package routines - used for partitions

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package
true value report-failure

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package dup  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
   else
      report-failure  if
         ." Can't open disk label package"  cr
      then
   then
;

: block-size  ( -- n )  h# 200  ;

: max-transfer  ( -- n )   h# 800  ;
\ : max-transfer  ( -- n )   h# 200  ;

: read-blocks   ( adr block# #blocks -- #read )
   dup >r  lba-get-sectors  if          ( adr r: #blocks )
      r> 2drop 0                        ( #read )
   else                                 ( adr dma-adr r: #blocks )
      swap  r@ sectors>bytes  do-lmove  ( r: #blocks )
      r>                                ( #read )                
   then
;
: write-blocks  ( adr block# #blocks -- #written )
   dup >r  lba-write-sectors  if  r> drop 0  else  r>  then
;

: #blocks  ( -- u )  mdp-size drop  ;

: lba-nand?  ( -- false | open-ok? true )
   read-lba-id  c@  dup 0=  swap h# ff =  or  if  false exit  then

   setup

   init-deblocker  0=  if  false true exit  then

   init-label-package  0=  if
      deblocker close-package false true exit
   then

   true true
;

: lba-close  ( -- )
   label-package  if  label-package close-package  then
   deblocker  if  deblocker close-package  then
   cache-flush
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: lba-size?  ( -- false | d.size true )
   label-package  if
      " size" label-package $call-method   ( d.size )
      true
   else
      false
   then
;

\ dend

\ begin-select /nandflash
\ setup


[ifdef] notdef

PNR - Pure NAND Read  (raw mode) - first 256 2K pages (512 KiB) - power-on state

VFP - Vendor Firmware Partition - 8 MBytes

MDP - Multimedia Data Partition - enter mode with FC command

BCM - Boot Code Maintenance - used for writing to PNR partition



sequence feature (1)

00 00 02 00 01 00 30 data  data length can be select 512 or 528 (2048 or 2112)  OOB data is dummy

sequence feature (2)

Type A

00      00 02 00 01 00      30   <sector data>   00  <dummy address 5 bytes>  30  <sector data>  ...
    reading command setup

Type B

00      00 02 00 01 00      30   <sector data>   f8  <sector data> ...

VFD/MDP mode - OOB is ignored on write, dummy on read
PNR access mode boot area (the first 256 2K pages - 512 KiB) - OOB is read/write


Low-level driver init:

Select transfer mode (whether to send dummy address and command for each data transfer - mode A or mode B)

Disable ECC

Select data length - 512 / 528, 2048 / 2112


--
Device comes up in raw NAND mode

Mode changes puts it in MDP mode or VFP mode

VFP mode is for program code
MDP mode is for data

----
Commands:
PNR mode:
 Boot mode 1:
  Page read (sequential) -  <00> {00} {00} {page#0} {page#1} {page#2} <30> RDY {page data}  ({Dummy page address})
  Page number reset to 0 -  <ff> RDY 
 Boot mode 2:
  Page read (sequential) -  <00> {AD0} {AD1} {page#0} {page#1} {page#2} <30> RDY {page data}  ({Dummy page address})
  Reset (noop)           -  <ff> RDY
 Boot mode 3:
  Page read (sequential) -  <00> {xx} {xx} {xx} {xx} {xx} <30> {page data}
  Reset (noop)           -  <ff> RDY

 Enter LBA mode          -  <fc> RDY   0020.00fc 0 0 >cmd
 Enter PNR mode          -  <fd> RDY   0020.00fd 0 0 >cmd

 Enter BCM mode          -  <00> {xx} {xx} {xx} {FC} {xx} <30> RDY


LBA mode:
 Sector Read Type A -  <00> {cnt0} {cnt1} {sec#0} {sec#1} {sec#2} <30> RDY {data}  (repeat all w dummy page address ...)
   Retransmit          -  {prevdata}  <31> RDY <00> {dummy 5-byte page address} <30> RDY {data}
 Sector Read Type B -  <00> {cnt0} {cnt1} {sec#0} {sec#1} {sec#2} <30> RDY {data}  (<f8> {data} ...)
   Retransmit         -   {prevdata}  <31> RDY {data}
 Sector Read Type C -  <00> {cnt0} {cnt1} {sec#0} {sec#1} {sec#2} <30> RDY {data}  ({data} ...)
   Retransmit         -   {prevdata}  RDY <31> RDY {data}

 Sector Write Type A - <80> {cnt0} {cnt1} {sec#0} {sec#1} {sec#2} <10> RDY {data}  (repeat all w dummy page address ...)
 Sector Write Type B - <80> {cnt0} {cnt1} {sec#0} {sec#1} {sec#2} <10> RDY {data}  (<80> {data} <10> RDY ...)

 Switch to PNR partition in BCM mode -  <00> {BF} {xx} {xx} {xx} {xx} <57> RDY

 Get MDP size - <00> {B0} {xx} {xx} {xx} {xx} <57> RDY {5 bytes LSB .. MSB}  (total #sectors in MDP)
 Get VFP size - <00> {B5} {xx} {xx} {xx} {xx} <57> RDY {2 bytes LSB .. MSB}  (total #sectors in VFP)
 Set VFP size - <00> {22} {SZ0} {SZ1} {/SZ0} {/SZ1} <57> RDY  (clears VFP and MDP data)
 Get EX_VFP size variation - <00> {B8} {10} {xx} {xx} {xx} <57> RDY {capacity_type, capacity_parameter}
 Set EX_VFP size           - <00> {24} {type} {param} {/type} {/param} <57> RDY
 Get EX_VFP size           - <00> {B7} {xx} {xx} {xx} {xx} <57> RDY {model_type, capacity_parameter}

 Set VFP Password - <00> {21} {OldPW1} {OldPW2} {PW1} {PW2} <57> RDY

 Set protocol 1 - <00> {A2} {param} {xx} {xx} {xx} <57> RDY  (param is N in (512+16)*N }
 Get protocol 1 - <00> {B2} {xx} {xx} {xx} {xx} <57> RDY  {param 1 byte}  (param is N in (512+16)*N)

 Set protocol 2 - <00> {A3} {param} {xx} {xx} {xx} <57> RDY  (param is A,B,C select}
 Get protocol 2 - <00> {B3} {xx} {xx} {xx} {xx} <57> RDY  {param 1 byte}  (param is A,B,C select)

 Set Min busy time - <00> {A4} {param} {xx} {xx} {xx} <57> RDY
 Get Min busy time - <00> {B4} {xx} {xx} {xx} {xx} <57> RDY  {param 1 byte}
 Get Max busy time - <00> {B9} {xx} {xx} {xx} {xx} <57> RDY  {read 2 bytes LE} {write 2 bytes LE} {flush 2 bytes LE}

 Power Down - <00> {BA} {xx} {xx} {xx} {xx} <57> RDY
 Power Up   - <00> {BB} {xx} {xx} {xx} {xx} <57> RDY

 High Speed Write Mode On  - <00> {BC} {xx} {xx} {xx} {xx} <57> RDY
 High Speed Write Mode Off - <00> {BD} {xx} {xx} {xx} {xx} <57> RDY
 
 Set Garbage Address Area - <00> {E5} {xx} {xx} {xx} {xx} <57> RDY (<80> {seccnt0, 1 secaddr0, 1, 2} <10> RDY) ... <00> <5f> {xx} {xx} {xx} {xx} <57> RDY
 Cache Flush before power down - <F9> RDY
 Vendor Option                 - <00> {8A} {vendor_code 98} {ven_def0} {ven_def1} {ven_def2} <57> RDY {ven_def 3-7}

BCM Mode:
 Read PNP Page             -  <00> {00} {00} {page#} {00} {00} <30> RDY {2112 bytes}
 Write partial PNP Page    -  <80> {col_adr0} {col_adr1} {page#} {len0} {len1} <30> RDY {up to 2112 bytes} <10> RDY
 Cache Flush in BCM mode   -  <00> {xx} {xx} {xx} {F9} {xx} <30> RDY
 Device Reboot in BCM mode -  <80> {xx} {xx} {xx} {FD} {xx} <10> RDY  (back to PNR read mode)
 Set Boot Mode 1           -  <00> {xx} {xx} {xx} {11} {xx} <30> RDY
 Set Boot Mode 2           -  <00> {xx} {xx} {xx} {22} {xx} <30> RDY
 Set Boot Mode 3           -  <00> {xx} {xx} {xx} {33} {xx} <30> RDY
 Set Reboot Mode FD        -  <00> {xx} {xx} {xx} {AD} {xx} <30> RDY
 Set Reboot Mode FD/FF     -  <00> {xx} {xx} {xx} {AF} {xx} <30> RDY
 Get persistent modes      -  <00> {xx} {xx} {xx} {99} {xx} <30> RDY [boot_mode_value-11/22/33, reboot_mode-AD/AD]


All Modes:
 Read ID 1 (fake ID)     -  <90> {00} {5 ID bytes}   (emulated SLC 4Gbit ID)
 Read ID 2 (real ID)     -  <92> {00} {5 ID bytes}   (LBA-ID

 Switch to MDP partition  -  <FC> RDY
 Switch to VFP partition  -  <00> {BE} {PW0} {PW1} {xx} {xx} <57> RDY  (PW: password - default FF)

 Unique ID         - <00> {9E} {xx} {xx} {xx} {xx} <57> RDY  <00> {01} {00} {00} {00} {00} <30> RDY  {ID data}    <00> {9F} {xx} {xx} {xx} {xx} <57> RDY
 Firmware version  - <00> {9E} {xx} {xx} {xx} {xx} <57> RDY  <00> {01} {00} {10} {00} {00} <30> RDY  {FW version} <00> {9F} {xx} {xx} {xx} {xx} <57> RDY
 Firmware version  - <00> {9E} {xx} {xx} {xx} {xx} <57> RDY  <00> {01} {00} {20} {00} {00} <30> RDY  {FW version} <00> {9F} {xx} {xx} {xx} {xx} <57> RDY

 R/W Terminate -   <fb> RDY   (must first wait for RDY except for read types A&B)

 Device Reboot to PNR mode     - <FD> RDY (<FF> RDY)
[then]
