\ Manufacturing test boot script for ASSY state

visible

\ If the firmware file is on a CIFS share on the factory server, it
\ should be read-only so multiple clients can read it simultaneously.

false value update-firmware?          \ Make this true to update firmware
: wanted-fw$  ( -- $ )  " q3a25"  ;   \ Set this value to the firmware version

: swid$  ( -- adr len )  " OFW ASSY test $Revision$"  ;

\ Location of the files containing KA tag data
: ka-dir$  ( -- adr len )  " http:\\10.1.0.1\ka\"  ;

: find-firmware-file  ( -- name$ )
   wanted-fw$  " u:\\boot\\%s.rom" sprintf    ( name$ )
   ." Trying " 2dup type cr                 ( name$ )
   2dup $file-exists?  if  exit  then       ( name$ )
   2drop                                    ( )

   wanted-fw$ factory-server$ " %s\\%s.rom" sprintf  ( name$ )
   ." Trying " 2dup type cr                 ( name$ )
   2dup $file-exists?  if  exit  then       ( name$ )
   2drop

   true  abort" Can't find new firmware file" 
;

: ?update-firmware  ( -- )
   update-firmware?  0=  if  exit  then
   \ Exit if the existing firmware and the wanted firmware are the same
   fw-version$  wanted-fw$  nocase-$=  if  exit  then
   ." Updating firmware to version " fw-version$ type cr
   d# 2000 ms
   ?enough-power
   find-firmware-file  $get-file  reflash
;

: put-ka-tag  ( value$ key$ -- )
   2over  8 min  ka-dir$ " %s%s" sprintf  ( value$ key$ filename$ )
   $read-file  if                     ( value$ key$ )
      ." ERROR: No KA tag file for " 2swap type cr  ( key$ )
      2drop                           ( )
   else                               ( value$ key$ file-data$ )
      2swap ($add-tag)                ( value$ )
      2drop                           ( )
   then
;

: special-tag?  ( value$ key$ -- true | value$ key$ false )
   2dup " KA" $=  if                      ( value$ key$ )
      put-ka-tag  true  exit
   then                                   ( value$ key$ )
   false
;

: put-tag  ( value$ key$ -- )
   special-tag?  if  exit  then           ( value$ key$ )
   put-ascii-tag
;

: check-smt-status  ( -- )
   " SS" find-tag  0= abort" Board failed SMT !!!"   ( adr len )
   -null                                             ( adr len' )
   " EN" $= 0=  abort" Board failed SMT !!!!"        ( )
;

: fwver$  ( -- adr len )  h# ffff.ffc6 6  ;
: board#$  ( -- adr len )
   " B#" find-tag  0= abort" Missing B# tag !!!"
   -null
;

d# 20 buffer: sn-buf
: sn$  ( -- adr len )  sn-buf count  ;

: try-get-sn  ( -- )
   sn-buf 1+ d# 20 accept   ( n )
   d# 12 <>  if
      " Wrong length, try again" .problem
      false exit
   then
   sn-buf 1+ " TSHC" comp  if
      " Must begin with TSHC, try again" .problem
      false exit
   then
   sn-buf 2+  sn-buf 1+  d# 11 move  \ Elide the T
   d# 11 sn-buf c!
   true
;

: get-sn  ( -- )
   ." *****"

   begin
      " Please Input Serial Number ......" .instructions
      try-get-sn
   until
;

d# 38 buffer: uuid-buf
: uuid$  ( -- )  uuid-buf count  ;

: uuid-bytes  ( n -- )
   push-hex
   0  ?do
      random-byte (.2)  2dup upper  uuid-buf $cat
   loop
   pop-base
;

: make-uuid  ( -- )
   0 uuid-buf c!
   4 uuid-bytes  " -" uuid-buf $cat
   2 uuid-bytes  " -" uuid-buf $cat
   2 uuid-bytes  " -" uuid-buf $cat
   2 uuid-bytes  " -" uuid-buf $cat
   6 uuid-bytes
;

d# 20 buffer: mac-buf
: mac$  ( -- )  mac-buf count  ;

: format-mac-address  ( adr len -- )
   0 mac-buf c!
   push-hex
   drop
   5 0  do     ( adr )
      dup c@ (.2)  mac-buf $cat  ( adr )
      " -" mac-buf $cat          ( adr )
      1+                         ( adr )
   loop                          ( adr )
   c@ (.2)  mac-buf $cat         ( )
   mac$ upper                    ( )
   pop-base
;

: get-mac  ( -- )
   " /wlan:force" open-dev  ?dup  if   ( wlan-ih )
      >r
      " local-mac-address" r@ ihandle>phandle get-package-property  if
         " XX-XX-XX-XX-XX-XX"  mac-buf place
      else                             ( adr len )
         format-mac-address            ( )
      then
      r> close-dev
   else
      " XX-XX-XX-XX-XX-XX"  mac-buf place
   then
;

: swdl-date$  ( -- adr len )
   push-decimal
   today swap rot  <# u# u# drop u# u# drop u# u# u# u# u#>
   pop-base
;
: get-info  ( -- )
   check-smt-status
   get-mac
   make-uuid
   get-sn
;

0 0 2value response$

: execute-downloads  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] : left-parse-string  ( rem$ value$ key$ )
      " Command" $=  if           ( rem$ value$ )
         evaluate                 ( rem$ )
      then                        ( rem$ value$ )
      2drop                       ( rem$ )
   repeat                         ( rem$ )
   2drop                          ( )
;

: parse-tags  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] : left-parse-string  ( rem$ value$ key$ )
      dup 2 =  if                 ( rem$ value$ key$ )
         put-tag                  ( rem$ )
      else                        ( rem$ value$ key$ )
         4drop                    ( rem$ )
      then                        ( rem$ )
   repeat                         ( adr len )
   2drop                          ( )
;

: inject-tags  ( -- )
   get-mfg-data

   " TS"  ($delete-tag)
   " MS"  ($delete-tag)
   " BD"  ($delete-tag)
   " NT"  ($delete-tag)

   sn$          " SN"  put-tag
   fwver$       " BV"  put-tag
   swid$        " T#"  put-tag
   uuid$        " U#"  put-tag
   mac$         " WM"  put-tag
   swdl-date$   " SD"  put-tag

   response$ parse-tags

   flash-write-enable
   (put-mfg-data)
   no-kbc-reboot
   kbc-on
;

: make-assy-request  ( -- )
   sn$ " %s.txt" sprintf open-temp-file
   mac$    " WM:" put-key+value
   uuid$   " U#:" put-key+value
   swid$   " T#:" put-key+value
   fwver$  " BV:" put-key+value
   board#$ " B#:" put-key+value
   sn$     " SN:" put-key+value
;

: assy-tag-exchange  ( -- )
   make-assy-request          ( )
   " Request" submit-file     ( )
   " Response" get-response to response$
;

: start-assy-test  ( -- )
   ?update-firmware

   wait-lan

   get-info

   ." Getting server response "
   cifs-connect  assy-tag-exchange  cifs-disconnect
   ." Done" cr

   response$ execute-downloads
   inject-tags

   ." Powering off ..." d# 2000 ms
   power-off
;

start-assy-test
