\ See license at end of file
purpose: IDE bus package implementing a "ide" device-type interface.

\ Before loading this file, first load a file that defines a "reg"
\ property and "(map)" and "(unmap)" words.

hex

headers

0 encode-int  " #size-cells" property

4 value max#drives

true value first-open?
0 value open-count
0 value pri-chip-base
0 value pri-dor
0 value sec-chip-base
0 value sec-dor
0 value dor-magic		\ DOR register bits that must always be set
0 instance value chip-base
0 instance value dor
0 instance value drive
0 instance value log-drive	\ drives 0 and 1 are on primary ide,
				\ 2 and 3 are on secondary ide

\ arrays of logical drive information
create /block       0 , 0 , 0 , 0 ,	\ drives are assumed not exist
\ drives are assumed IDE initially
create atapi-drive? false , false , false , false ,
create drive-type   0 , 0 , 0 , 0 ,	\ drives are assumed to be hard drive
create '/secs       0 , 0 , 0 , 0 ,
create '/heads      0 , 0 , 0 , 0 ,
create '/cyls       0 , 0 , 0 , 0 ,
create '/lba        0 , 0 , 0 , 0 ,

\ words to access the arrays
: array>  ( array-base -- indexed-addr )  log-drive cells +  ;
: /block@  ( -- block-size )  /block array> @  ;
: /block!  ( block-size -- )  /block array> !  ;
: drive-type@  ( -- type )  drive-type array> @  ;
: drive-type!  ( type -- )  drive-type array> !  ;
: atapi-drive?@  ( -- atapi? )  atapi-drive? array> @  ;
: atapi-drive?!  ( atapi? -- )  atapi-drive? array> !  ;
: /secs   ( -- spt )    '/secs  array> @  ;
: /secs!  ( spt -- )    '/secs  array> !  ;
: /cyls   ( -- cyls )   '/cyls  array> @  ;
: /cyls!  ( cyls -- )   '/cyls  array> !  ;
: /heads  ( -- heads )  '/heads array> @  ;
: /heads! ( heads -- )  '/heads array> !  ;
: /lba    ( -- #secs )  '/lba   array> @  ;
: /lba!   ( #secs -- )  '/lba   array> !  ;

\ Register definitions

\ 0 constant r-data
\ 1 constant r-error
\ 2 constant r-#secs
\ 3 constant r-sector
\ 4 constant r-cyl-lsb
\ 5 constant r-cyl-msb
\ 6 constant r-drive/head
\ 7 constant r-csr

\ Access methods

: reg@  ( reg#  --  data )  chip-base + rb@  ;

: r-data@   ( -- data  )  chip-base w@  ;
: r-error@  ( -- error )  1 reg@  ;
: r-#secs@  ( -- #secs )  2 reg@  ;
: r-sector@ ( -- secno )  3 reg@  ;
: r-cyl@    ( -- cylno )  4 reg@  5 reg@  bwjoin  ;
: r-head@   ( -- head# unit )  6 reg@ dup 0f and swap 4 rshift 1 and  ;
: r-csr@    ( -- stat  )  7 reg@  ;
: r-dor@    ( -- stat  )  dor rb@ ;
: r-dor!    ( val   -- )  dor-magic or dor rb!  ;

\ Spin until BSY == 0, RDY == 1, indicating registers can be touched
: wait-while-busy  ( -- )
   get-msecs                            ( start-time )
   begin
      r-csr@                            ( start-time csr )
      dup 0<>                           ( start-time csr flag )
      over h# ff <>             and     ( start-time csr flag )
      swap h# c0 and  h# 40 <>  and     ( start-time csr=0|ff|4x? )
   while				( start-time )
      get-msecs over -                  ( start-time delta )
      d# 5000 <                         ( start-time timeout? )
   while				( start-time )
   repeat
   then				        ( start-time )
   drop					( )
;

: reg!  ( data reg#  --  )  wait-while-busy  chip-base + rb!  ;

: r-data!   ( data  -- )  chip-base w!  ;
: r-features!  ( data -- )  1 reg!  ;
: r-#secs!  ( #secs -- )  2 reg!  ;
: r-sector! ( secno -- )  3 reg!  ;
: r-cyl!    ( cylno -- )  wbsplit  5 reg!  4 reg!  ;

\ XXX we should probably convert to logical block addressing, in which
\ case we would use e0 instead of a0

: r-head!   ( head# unit -- )  4 lshift h# a0 or or  6 chip-base +  rb!  ;
: r-csr!    ( cmd   -- )  7 reg!  ;

defer io-blk-w!  defer io-blk-w@
: (io-blk-w!)  ( adr len port -- )
   -rot bounds  do  i c@  i 1+ c@  bwjoin  over rw!  /w +loop  drop
;
: (io-blk-w@)  ( adr len port -- )
   -rot bounds  do  dup rw@  wbsplit  i 1+ c!  i c!  /w +loop  drop
;
' (io-blk-w!) to io-blk-w!
' (io-blk-w@) to io-blk-w@


\ Command definitions

\ 10 constant calibrate-cmd
\ 20 constant read-cmd
\ 30 constant write-cmd
\ 40 constant verify-cmd
\ 50 constant format-cmd
\ 70 constant seek-cmd
\ 90 constant diag-cmd
\ 91 constant set-drive-parms-cmd
\ ec constant identify-cmd

: wait-until-drq  ( -- )
   begin
      r-csr@
      dup 1 and  if  ." IDE data error: " r-error@ . cr abort  then
      h# c8 and h# 48 =
   until
;
: wait-until-ready  ( -- )  begin  r-csr@ h# 50 =  until  ;

: lblk>cyl-head-sect  ( block# -- cyl# head# sect# )
   /secs /mod                                 ( sect# residue )
   /heads /mod swap rot 1+                    ( cyl# head# sect# )
;

defer rblock  ( adr len -- error? )
defer pio-end-hack  ' noop to pio-end-hack
defer pio-start-hack  ' noop to pio-start-hack
: pio-rblock  ( adr len -- error? )
   wait-until-drq
   pio-start-hack
   chip-base io-blk-w@  false
   pio-end-hack
;
' pio-rblock to rblock

: (rblocks)  ( adr #blks -- actual# )
   0 -rot                                       ( actual#blks adr #blks )
   /block@ *  bounds  ?do                       ( actual#blks )
      i /block@ rblock  if  unloop exit  then   ( actual#blks )
      1+                                        ( actual#blks' )
   /block@ +loop                                ( actual#blks )
;
: pio-rblocks  ( addr #blks -- actual# )
   ['] pio-rblock to rblock
   h# 20 r-csr!
   (rblocks)
;
defer rblocks
' pio-rblocks to rblocks

: pio-wblock  ( adr len -- error? )
   wait-until-drq
   pio-start-hack
   chip-base io-blk-w!  false
   pio-end-hack
;
: wblocks  ( addr #blks -- actual# | error )
   over >r                                      ( addr #blks ) ( R: addr )
   h# 30 r-csr!

   begin
      wait-until-drq
      swap                                      ( #blks addr ) ( R: addr )

      pio-start-hack
      dup /block@ chip-base io-blk-w!
      pio-end-hack

      /block@ +                                 ( #blks addr' ) ( R: addr )
      swap 1- ?dup 0=
   until
   r> - /block@ /
;

\ Read or write "#blks" blocks starting at "block#" into memory at "addr"
\ Input? is true for reading or false for writing.

: r/w-blocks  ( addr block# #blks input? -- actual# )

   over 0=  if  2drop 2drop 0 exit  then

   >r dup >r r-#secs!                        ( addr block# ) ( R: input? #blks )
   /lba  if                                  ( addr block# ) ( R: input? #blks )
      lbsplit                                ( addr 0-7 8-15 16-23 24-32 )
      \ 4, when shifted with drive, sets the LBA bit
      h# f and  drive 4 or  r-head!          ( addr 0-7 8-15 16-23 )
      bwjoin r-cyl!  r-sector!               ( addr   R: input? #blks )
   else                                      ( addr block# ) ( R: input? #blks )
      lblk>cyl-head-sect                     ( addr cyl# head# sect# )
      r-sector! drive r-head! r-cyl!         ( addr #blks input? R: input? #blks )
   then
   r>  r>  if  rblocks  else  wblocks  then               ( actual# | error )

   dup 0=  if
      ." Failed to transfer any blocks" cr
      \ XXX trouble
   then                                           ( actual# )
;

\ Determine the physical constants of this drive.
\ XXX - IDENTIFY is not a required command! Still, most drives
\ we'll see will implement it. If this doesn't work, we'll have to
\ read CMOS drive parameters or something equally unpleasant.

\ /block buffer: scratchbuf
create scratchbuf d# 512 allot

fload ${BP}/dev/ide/atapi.fth

: le-w@  ( adr -- w )  dup c@ swap ca1+ c@ bwjoin  ;

: ide-get-drive-parms  ( -- )
   d# 512 /block!

   false  atapi-drive?!
   0      drive-type!

   wait-while-busy
   2 r-dor!             \ Turn off IRQ14

   0 drive r-head!

   h# ec r-csr!		\ Identify command

   scratchbuf d# 512 pio-rblock drop

   scratchbuf 1 wa+ le-w@ /cyls!
   scratchbuf 3 wa+ le-w@ /heads!
   scratchbuf 6 wa+ le-w@ /secs!

\   /cyls h# 3fff u>=  if
   scratchbuf d# 49 wa+ w@ h# 200 and  if  \ LBA
      scratchbuf d# 60 wa+ le-w@
      scratchbuf d# 61 wa+ le-w@
      wljoin /lba!
   then
;

: get-drive-parms  ( -- )
   \ Reset this string (primary or secondary) on the first time through,
   \ in order to clear any errors that might be hanging around from uses
   \ of the drive by previous software.
   drive 0=  if  4 r-dor!  0 r-dor!  then

   wait-while-busy
   0 drive r-head!		\ select drive
   0 r-dor!			\ flush ISA bus
   6 reg@ h# a0 drive 4 lshift or  = if
      r-cyl@ eb14 =  if
         \ If H/W reset resets the IDE bus, there's no need for atapi-reset
	 \ Unfortunately, the vl-reset on the Shark does not seem to fully
	 \ reset the ATAPI drive, therefore, we are doing it here.
         atapi-reset		\ atapi soft reset
         atapi-get-drive-parms
      else
         r-csr@ 0<>  r-csr@ h# ff <>  and  if
            drive 0=  if  wait-until-ready  then	\ wait until spin-up
            r-csr@ h# f0 and h# 50 =  if  ide-get-drive-parms  then
         then
      then
   then
;

external

: block-size  ( -- n )  0 drive r-head!  /block@  ;
: #blocks  ( -- n )
   atapi-drive?@  if
     atapi-capacity
   else
     /lba ?dup  0=  if               ( )
        /cyls /secs /heads * *       ( #blocks )
     then                            ( #blocks )
   then                              ( #blocks )
;

: dma-alloc  ( n -- vaddr )  " dma-alloc" $call-parent  ;
: dma-free  ( vaddr n -- )  " dma-free" $call-parent  ;
: max-transfer  ( -- n )   d# 256 /block@ *  ;
: read-blocks   ( addr block# #blocks -- #read )
   atapi-drive?@  if  atapi-read  else  true  r/w-blocks  then
;
: write-blocks  ( addr block# #blocks -- #written )
   atapi-drive?@  if  atapi-write  else  false r/w-blocks  then
;
: ide-inquiry  ( -- false | drive-type true )
   /block@ 0=  if  false  else  drive-type@ true  then
;
: ide-drive-inquiry  ( log-drive -- false | drive-type true )
   dup max#drives >=  if  drop false  else  to log-drive  ide-inquiry  then
;

: set-address  ( dummy unit -- )
   \ units 0 and 1 are primary ide drives, 2 and 3 are secondary ide drives
   nip dup to log-drive 1 and to drive
   log-drive 2 <  if  pri-chip-base pri-dor  else  sec-chip-base sec-dor  then
   to dor to chip-base
;

\ For switching between programmed-I/O and DMA operational modes

0 instance value 'open-dma
0 instance value 'close-dma
0 instance value 'set-drive-cfg
defer close-dma  ' noop is close-dma
defer open-dma   ' noop to open-dma
defer set-drive-cfg  ' noop to set-drive-cfg
: save-dma-open  ( -- )
   ['] open-dma      behavior to 'open-dma
   ['] close-dma     behavior to 'close-dma
   ['] set-drive-cfg behavior to 'set-drive-cfg
;
: restore-open-dma  ( -- )
   'open-dma      ?dup  if  to open-dma       then
   'close-dma     ?dup  if  to close-dma      then
   'set-drive-cfg ?dup  if  to set-drive-cfg  then
;

: parse-args  ( -- flag )
   my-args  begin  dup  while       \ Execute mode modifiers
      ascii , left-parse-string            ( rem$ first$ )
      my-self ['] $call-method  catch  if  ( rem$ x x x )
         ." Unknown argument" cr
         3drop 2drop false exit
      then                                 ( rem$ )
   repeat                                  ( rem$ )
   2drop
   true
;

: open-hardware  ( -- flag )
   parse-args 0=  if  false exit  then
   (map)  to sec-dor  to sec-chip-base  to pri-dor  to pri-chip-base
   open-dma

   first-open?  if
      max#drives 0  do
         0 i  set-address  get-drive-parms  set-drive-cfg  loop
      false to first-open?
   then

   0 0 set-address		\ Default

   \ should perform a quick "sanity check" selftest here,
   \ returning true iff the test succeeds.

   true
;
: reopen-hardware  ( -- flag )  parse-args  ;

: close-hardware  ( -- )
   close-dma   
   pri-chip-base pri-dor sec-chip-base sec-dor (unmap)
   restore-open-dma
;
: reclose-hardware  ( -- )  restore-open-dma  ;

: selftest  ( -- 0 | error-code )
   \ perform reasonably extensive selftest here, displaying
   \ a message if the test fails, and returning an error code if the
   \ test fails or 0 if the test succeeds.
   0
;

: open  ( -- flag )
   open-count  if
      reopen-hardware  dup  if  open-count 1+ to open-count  then
      exit
   else
      open-hardware  dup  if
         1 to open-count
      then
   then
;
: close  ( -- )
   open-count 1- to open-count
   open-count  if
      reclose-hardware
   else
      close-hardware
   then
;

: set-blk-w  ( w@-addr w!-addr -- )  to io-blk-w! to io-blk-w@  ;

[ifdef] notyet
: set-pio-mode  ( mode -- )
   3 r-features!
   8 or r-#secs!
   h# ef r-csr!
;
[then]
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
