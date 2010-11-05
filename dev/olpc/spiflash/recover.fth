\ Use a working OLPC board to recover one whose firmware is bad,
\ using the serial recovery method.
\ This is similar to the serial recovery procedure described at
\ http://wiki.laptop.org/go/SPI_FLASH_Recovery , but uses an
\ OLPC board as the host system, thus avoiding the following problems:
\
\ a) Many PCs these days don't have built-in serial ports, and
\    USB serial ports often don't work well with the serial
\    recovery procedure.
\ b) The timing characteristics of Linux serial drivers is not
\    predictable, which sometimes results in failures of the
\    recovery procedure.  In other cases, it causes the recovery
\    process to take much longer than necessary.
\
\ The commands are:
\    ok clone                   \ Copies this machine's FLASH to the dead one
\    ok recover disk:\file.rom  \ Copies a ROM file to the dead one

: (serial-flash)  ( -- )
   \ Disconnect serial port from console multiplexor
   ." Disconnecting serial port from OFW console" cr
   fallback-in-ih  remove-input
   fallback-out-ih remove-output

   ." Connecting to dead machine.  (Merging will take about 25 seconds.)" cr
   use-serial-ec
   reflash
   use-local-ec
;

: clone  ( -- )
   ." Getting a copy of this machine's FLASH" cr
   safe-flash-read
   true to file-loaded?

   (serial-flash)
;

: recover  ( "filename" -- )  get-file (serial-flash)  ;
