purpose: Flash ROM programming for EON EN29LV800 - untested
\ See license at end of file

\ This file depends on an environment-specific file containing
\ /flash, fctl!, fdata!, fc@ and enable-flash-writes

hex
10.0000 to /flash
d# 19 value #sectors
defer enable-flash-writes  ' noop to enable-flash-writes
defer fctl!
defer fdata!

\ magic numbers
h# 5555 constant addr0
h# 2aaa constant addr1

create bb-sectors  0 l, h# 4000 l, h# 6000 l, h# 8000 l,
                   h# 1.0000 l, h# 2.0000 l, h# 3.0000 l, h# 4.0000 l,
                   h# 5.0000 l, h# 6.0000 l, h# 7.0000 l, h# 8.0000 l,
                   h# 9.0000 l, h# a.0000 l, h# b.0000 l, h# c.0000 l,
                   h# d.0000 l, h# e.0000 l, h# f.0000 l,

create bt-sectors  0 l,
                   h# 1.0000 l, h# 2.0000 l, h# 3.0000 l, h# 4.0000 l,
                   h# 5.0000 l, h# 6.0000 l, h# 7.0000 l, h# 8.0000 l,
                   h# 9.0000 l, h# a.0000 l, h# b.0000 l, h# c.0000 l,
                   h# d.0000 l, h# e.0000 l,
                   h# f.0000 l, h# f.8000 l, h# f.a000 l, h# f.c000 l,

defer sector-map  ' bb-sectors to sector-map
: sector>offset  ( sector -- offset )  /l * sector-map + l@  ;
: sector>size    ( sector -- size )
   dup 1+ #sectors =  if  /flash  else  dup 1+ sector>offset  then
   swap sector>offset -
;
: offset>sector  ( offset -- sector )
   #sectors 1-  #sectors 0  do
      over i sector>offset i sector>size + u<  if  drop i leave  then
   loop  nip
;
: offset+len>sectors  ( offset len -- end#+1 start# )
   over offset>sector -rot
   + 1- offset>sector 1+ swap
;

\ the command sequence
: unlock-write  ( -- )  h# aa addr0 fctl!  h# 55 addr1 fctl!  ;
: flashmode   ( n -- )   addr0 fctl!  ;

\ normal mode, acts like a ROM
: read-mode         ( -- )   h# f0 flashmode  ;

\ note side effect: writes stay enabled!
: autoselect-mode   ( -- )
   enable-flash-writes
   unlock-write  h# 90 flashmode  
;

\ these need to recognize more cases. What are the numbers?
: .fl-manuf   ( n -- )
   case
          1  of  ." AMD "  endof
         1c  of  ." EON "  endof
      h# 1f  of  ." ATMEL" endof
      h# 89  of  ." Intel "  endof
      dup .
   endcase
;
: .fl-dev   ( n -- )
   case
     h# 37  of  ." 29LV008BB "  endof
     h# 3e  of  ." 29LV008BT "  endof
     h# da  of  ." 29LV800bt "  endof
     h# 5b  of  ." 29LV800bb "  endof
     dup .
   endcase
;
: flash-type  ( -- device-type manufacturer )
   autoselect-mode  1 fc@  0 fc@  read-mode
;
: .flash-type	( -- )  flash-type  .fl-manuf .fl-dev  ;
: .flash   ( -- )  .flash-type  ;
: (?programmable)  ( -- )
   flash-type  1 =  if
      case
         h# 37  of  ['] bb-sectors to sector-map  endof
         h# 3e  of  ['] bt-sectors to sector-map  endof
         h# da  of  ['] bt-sectors to sector-map  endof
         h# 5b  of  ['] bb-sectors to sector-map  endof
         ( default )
            collect(
            ." Unsupported Flash device type: " .flash
            ." This firmware can currently program 29LV008B and 29LV800 devices."
            )collect alert
            abort
      endcase
   then
;
' (?programmable) to ?programmable

: .flash-protection  ( -- )
   autoselect-mode
   #sectors 0  do
      ." sector " i .d
      i sector>offset  ."  offset = " 8 u.r
      i sector>size    ."  size = " 8 u.r
      i sector>offset 2 + fc@  if  ."  protected"  else  ."  unprotected"  then
      cr
   loop
   read-mode
;
: ?partial-protected  ( offset len -- )
   2dup + /flash >  if
      collect(
      ." Image is too big." cr
      )collect alert
      abort
   then
   ['] (?programmable) catch  if  2drop abort  then
   autoselect-mode
   offset+len>sectors  ?do
      i sector>offset 2 + fc@  if
         read-mode
         collect(
         ." Cannot program flash." cr
         ." Sector " i .d ." is protected." cr
         )collect alert
         abort
      then
   loop
   read-mode
;

: clear-status   ( -- )   f0 flashmode  ;
\ wait until done, check for errors
: data-poll   ( n a -- hung? )
   begin
      2dup fc@ xor h# 80 and  while		( n a )	\ busy?
      dup fc@ h# 20 and if			( n a )	\ error?
	 fc@ xor h# 80 and abort" write failed "	\ abort on still busy
         exit						\ okay
      then
   repeat  2drop
;

: sector-erase   ( sector -- )
   enable-flash-writes
   unlock-write  h# 80 flashmode	\ setup
   unlock-write  dup sector>offset h# 30 over fctl!
   swap sector>size + 1- h# ff swap  ['] data-poll catch drop
   read-mode 
;
' sector-erase to flash-erase-block

: sector-erase-suspend   ( -- )   b0 addr0 fctl!  ;
: sector-erase-resume    ( -- )   30 addr0 fctl!  ;
: partial-erase  ( offset len -- )
   offset+len>sectors  ?do  i sector-erase  loop
;
: chip-erase  ( -- )
   enable-flash-writes
   unlock-write  h# 80 flashmode	\ setup
   unlock-write  h# 10 flashmode	\ chip erase
   h# ff /flash 1- ['] data-poll catch drop
   read-mode 
;
\ ' chip-erase to erase-flash

: write-byte   ( n a -- )
   2dup  unlock-write  h# a0 flashmode
   fdata!
   ['] data-poll catch if   clear-status   then
;
: (flash-write)   ( source-address length dest-offset -- )
   rot 0  ?do   over i + c@   over i + write-byte   loop  ( src dst )
   2drop  read-mode
;
' (flash-write) to flash-write

: (flash-verify)   ( source-address length dest-offset -- )
   rot 0  ?do                              ( src dst )
      over i + c@   over i + fc@  <> if    ( src dst )
	 ." Verify failed. At " dup i + dup . ." got " fc@ . 
	 ." expected " over i + c@ . abort
      then                                 ( src dst )
   loop  2drop                             ( )
;
' (flash-verify to flash-verify

: verify-erase   ( sector# -- error? )
   dup sector>offset swap sector>size   bounds ?do
      i fc@  h# ff  <> if
	 ." erase error at " i . ." got " i fc@ . cr
	 true leave
      then
   loop  false
;
: program-sector   ( address length sector -- )
   dup push-decimal 1 .r pop-base   ." E"
   dup sector-erase			( address length sector )
   dup verify-erase if			( address length sector )
      dup sector-erase dup verify-erase abort" Erase failure"
   then					( address length sector )
   dup sector>offset -rot sector>size min	( address sector-addr length' )
   bs emit ." W"
   3dup write-bytes			( address sector-addr length' )
   bs emit ." V"			( address sector-addr length' )
   verify-bytes				( )
   space
;

0 value start-sector
: (program-flash)   ( address length -- )  start-sector sector>offset swap  write-bytes  ;
' (program-flash) to program-flash
