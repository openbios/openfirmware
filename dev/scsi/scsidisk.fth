\ See license at end of file
purpose: SCSI disk package implementing a "block" device-type interface.

hex

" block"     device-type
" sd"  encode-string  " compatible" property

fload ${BP}/dev/scsi/scsicom.fth	\ Utility routines for SCSI commands

hex

\ 0 means no timeout
: set-timeout  ( msecs -- )  " set-timeout" $call-parent  ;

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

external
0 instance value label-package
true value report-failure
headers

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


\ Ensures that the disk is spinning, but doesn't wait forever

create sstart-cmd  h# 1b c, 0 c, 0 c, 0 c, 1 c, 0 c,

: timed-spin  ( -- error? )
   \ Set timeout to 45 sec: some large (>1GB) drives take
   \ up to 30 secs to spin up.
   d# 45 d# 1000 *  set-timeout

   0 0 true  sstart-cmd 6  -1 retry-command  if  ( true | sensebuf false )
      \ true on top of the stack indicates a hardware error.
      \ We don't treat "illegal request" as an error because some drives
      \ don't support the start command.  Everything else other than
      \ success is considered an error.
      if  true  else  2+ c@ 5 <>  then           ( error? )
   else                                          ( )
      false                                      ( false )
   then                                          ( error? )

   0 set-timeout
;

0 instance value /block         \ Device native block size

create mode-sense-bd          h# 1a c, 0 c, 0 c, 0 c, d# 12 c, 0 c,
create read-capacity-cmd h# 25 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 

: read-block-extent  ( -- true | block-size #blocks false )
   \ First try "read capacity" - data returned in bytes 4,5,6,7
   \ The SCSI-2 standard requires disk devices to implement
   \ the "read capacity" command.

   8  read-capacity-cmd 0a  short-data-command  0=  if
       dup 4 + 4c@  swap 4c@  1+  false  exit
   then

   \ Failing that, try "mode sense" with an allocation length big enough only
   \ for the header and the block descriptor, in case it's a SCSI-1 device

   d# 12  mode-sense-bd 6  short-data-command  0=  if           ( adr )
       dup 9 + 3c@  swap 4 + 4c@  false  exit
   then

   true
;
: read-block-size  ( -- n )     \ Ask device about its block size
   read-block-extent  if  d# 512  else  drop  then
;

external

[ifdef] report-geometry
create mode-sense-geometry    h# 1a c, 0 c, 4 c, 0 c, d# 36 c, 0 c,

\ The sector/track value reported below is an average, because modern SCSI
\ disks often have variable geometry - fewer sectors on the inner cylinders
\ and spare sectors and tracks located at various places on the disk.
\ If you multiply the sectors/track number obtained from the format info
\ mode sense code page by the heads and cylinders obtained from the geometry
\ page, the number of blocks thus calculated usually exceeds the number of
\ logical blocks reported in the mode sense block descriptor, often by a
\ factor of about 25%.

\ Return true for error, otherwise disk geometry and false
: geometry  ( -- true | sectors/track #heads #cylinders false )
   d# 36  mode-sense-geometry  6  short-data-command  if  true exit  then  >r
   r@ d# 17 + c@   r@ d# 14 + 3c@   ( heads cylinders )
   2dup *  r> d# 4 + 4c@            ( heads cylinders heads*cylinders #blocks )
   swap /  -rot                     ( sectors/track heads cylinders )
   false   
;
[then]

: #blocks  ( -- true | n false )
   read-block-extent  if  true  else  nip  then
;

\ Return device block size; cache it the first time we find the information
\ This method is called by the deblocker
: block-size  ( -- n )
   /block  if  /block exit  then        \ Don't ask if we already know

   read-block-size dup to /block
;

headers

\ Read or write "#blks" blocks starting at "block#" into memory at "addr"
\ Input? is true for reading or false for writing.
\ command is  8  for reading or  h# a  for writing
\ We use the 6-byte forms of the disk read and write commands where possible.

: 2c!  ( n addr -- )  >r lbsplit 2drop  r> +c!         c!  ;
: 4c!  ( n addr -- )  >r lbsplit        r> +c! +c! +c! c!  ;

: r/w-blocks  ( addr block# #blks input? command -- actual# )
   cmdbuf /cmdbuf erase
   2over  h# 100 u>  swap h# 20.0000 u>=  or  if  ( addr block# #blks dir cmd )
      \ Use 10-byte form
      h# 20 or  0 cb!  \ 28 (read) or 2a (write)  ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 2 + 4c!                              ( addr dir #blks )
      dup cmdbuf 7 + 2c!                          ( addr dir #blks )
      d# 10                                       ( addr dir #blks cmdlen )
   else                                           ( addr block# #blks dir cmd )
      \ Use 6-byte form
      0 cb!                                       ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 1+ 3c!                               ( addr dir #blks )
      dup 4 cb!                                   ( addr dir #blks )
      6                                           ( addr dir #blks cmdlen )
   then
   swap                                           ( addr dir cmdlen #blks )
   dup >r                                         ( addr input? cmdlen #blks )
   /block *  -rot  cmdbuf swap  -1  ( addr #bytes input? cmd cmdlen #retries )
   retry-command  if                              ( [ sensebuf ] hw? )
      0= if  drop  then  r> drop 0
   else
      r>
   then    ( actual# )
;

external

\ These three methods are called by the deblocker.

: max-transfer  ( -- n )   parent-max-transfer  ;
: read-blocks   ( addr block# #blocks -- #read )     true  d# 8  r/w-blocks  ;
: write-blocks  ( addr block# #blocks -- #written )  false d# 10 r/w-blocks  ;

\ Methods used by external clients

: open  ( -- flag )
   my-unit " set-address" $call-parent

   \ It might be a good idea to do an inquiry here to determine the
   \ device configuration, checking the result to see if the device
   \ really is a disk.

   \ Make sure the disk is spinning

   timed-spin  if  false exit  then

   block-size to /block

   init-deblocker  0=  if  false exit  then

   init-label-package  0=  if
      deblocker close-package false exit
   then

   true
;

: close  ( -- )
   label-package close-package
   deblocker close-package
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: size  ( -- d.size )  " size" label-package $call-method  ;
headers
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
