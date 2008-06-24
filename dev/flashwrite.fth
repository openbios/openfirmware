0 [if]
\ Write support is complicated by the need to erase before
\ writing and the possibly-different erase and write granularity.
\
\ For NOR FLASH, where you can write as many times as you want
\ while turning 1's into 0's, the algorithm is:
\
\ Break the entire write range into pieces each contained in one
\ erase unit.  For each piece:
\
\   Compare the existing and new contents to see if the unit needs erasing
\
\   If no bits need to go from 0 to 1, erase is unnecessary, so just write.
\   (It's a little more complicated if the write granularity is >1 byte.)
\
\   Otherwise, copy the existing contents of the erase unit to a buffer,
\   merge in the new data, erase, then write back the buffer.
[then]

\ dev /flash

[ifndef] flash-write-enable
also forth definitions
defer flash-write-enable   ( -- )
defer flash-write-disable  ( -- )
defer flash-erase-block    ( offset -- )
defer flash-write          ( adr len offset -- )
defer flash-read           ( adr len offset -- )
defer flash-verify         ( adr len offset -- )
h# 10.0000 value /flash
h# 10000 value /flash-block
previous definitions
[then]


: left-in-block  ( len offset -- #left )
   \ Determine how many bytes are left in the page containing offset
   /flash-block  swap /flash-block 1- and -  ( len left-in-page )
   min                                       ( #left )
;

: must-erase?  ( adr len -- flag )
   device-base seek-ptr +         ( adr len dev-adr )
   swap  0  ?do                   ( adr dev-adr )
      over i + c@  over i + c@    ( adr dev-adr new-byte old-byte )
      \ Must erase if a bit in old-byte is 0 and that bit in new-byte is 1
      invert and  if              ( adr dev-adr )
         2drop true unloop exit
      then                        ( adr dev-adr )
   loop                           ( adr dev-adr )
   2drop false
;

: erase+write  ( adr len -- )
   dup /flash-block =  if
      \ If we are going to overwrite the entire block, there's no need to
      \ preserve the old data.  This can only happen if we are already
      \ aligned on an erase block boundary.
      seek-ptr flash-erase-block           ( adr len )
      seek-ptr flash-write                 ( )
   else
      \ Allocate a buffer to save the old block contents
      /flash-block alloc-mem  >r                 ( adr len )

      seek-ptr /flash-block round-down           ( adr len block-start )

      \ Copy existing data from FLASH block to the buffer
      dup device-base +  r@  /flash-block lmove  ( adr len block-start )

      \ Merge new bytes into the buffer
      -rot                                       ( block-start adr len )
      seek-ptr /flash-block mod                  ( block-start adr len buf-offset )
      r@ +  swap move                            ( block-start )

      \ Erase the block and rewrite it from the buffer
      dup  flash-erase-block                     ( block-start )
      r@  /flash-block  rot  flash-write         ( )

      \ Release the buffer
      r> /flash-block free-mem
   then
;

: handle-block  ( adr len -- adr' len' )
   dup seek-ptr left-in-block         ( adr len #left )
   >r                                 ( adr len r: #left )
   over r@ must-erase?  if            ( adr len r: #left )
      over r@ erase+write             ( adr len r: #left )
   else                               ( adr len r: #left )
      over r@ seek-ptr flash-write    ( adr len r: #left )
   then                               ( adr len r: #left )
   seek-ptr r@ + to seek-ptr          ( adr len r: #left )
   r> /string                         ( adr' len' )
;

: write  ( adr len -- #written )
   flash-write-enable
   tuck                                       ( len adr len )
   begin  dup  while  handle-block  repeat    ( len adr' remain' )
   2drop                                      ( len )
   flash-write-disable
;

\ dend
