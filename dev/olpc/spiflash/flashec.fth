\ Command to replace just the EC bits in the FLASH.
\ This will cause the overall CRC near the end of the FLASH to be wrong,
\ but that won't prevent the system from working.

\ .( EC FLASH Program.  Example:   ok flash-ec disk:\PQ2B31.bin) cr

h# 1.0000 constant /ec

: flash-ec  ( "filename" -- )
   reading
   flash-buf  /ec  ifd @ fgets   ( len )
   ifd @ fclose

   /ec <> abort" EC image file is the wrong length"

   flash-write-enable

   \ merge-mfg-data

   flash-buf  /ec  0  write-flash-range   \ Write everything
;
