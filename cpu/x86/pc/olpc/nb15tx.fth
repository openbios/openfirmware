purpose: User interface for NAND multicast updater - transmission to XO-1.5
\ See license at end of file

\ This sender is for multicast operation over a wired network.
\ It is rarely used, because the wired multicast mode is primarily
\ used in the factory with a big server as the sender.
\ Example: wired-nb-tx: u:\os201.zd 224.0.0.2
: wired-nb-tx:  ( "filename" "multicast-ip-address" -- )
   false to already-go?
   safe-parse-word safe-parse-word
   " boot rom:nb_tx udp:%s %s 20 131072" sprintf eval
;

\ This sends to XO-1.5 receivers, but the sender itself can run on either XO-1 or XO-1.5.
\ On XO-1, you must load the special "thin" firmware from a USB stick.
: ?load-thin-wlan-fw  ( -- )
   " /wlan" find-package 0= abort" No /wlan device"  ( phandle )

   " thin" rot get-package-property  if              ( )
      \ Absence of "thin" property means we need to get special firmware
      " u:\usb8388t.bin" " wlan-fw" $setenv
      \ We have to reset the device and driver to force it to reload
      \ the thin firmware, in case firmware has already been loaded.
      wlan-reset
      " dev /wlan  ds-not-ready to driver-state  dend" evaluate
   else                                              ( adr len )
      \ Presence of "thin" property means we are good to go
      2drop
   then
;

: $nb-tx  ( filename$ channel# -- )
   >r 2>r  redundancy  2r> r>
   ?load-thin-wlan-fw
   false to already-go?

   " boot rom:nb_tx thinmac:OLPC-NANDblaster,%d %s %d 131072" sprintf eval
;

: nb-tx:  ( "filename" -- )
   redundancy                     ( redundancy )
   safe-parse-word                ( redundancy filename$ )
   nb-auto-channel                ( redundancy filename$ channel# )

   ?load-thin-wlan-fw
   false to already-go?

   " boot rom:nb_tx thinmac:OLPC-NANDblaster,%d %s %d 131072" sprintf eval
;
: #nb-secure  ( zip-filename$ image-filename$ channel# -- )
   depth 5 < abort" #nb-secure-update - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   load-read  sig$ ?save-string swap  ( siglen sigadr r: channel# image-filename$ )
   img$ ?save-string swap             ( siglen sigadr speclen specadr r: channel# image-filename$ )
   redundancy  2r> r>                 ( siglen sigadr speclen specadr redundancy image-filename$ channel# )
   " rom:nb_tx thinmac:OLPC-NANDblaster,%d %s %d 131072 %d %d %d %d" sprintf boot-load go
;
: #nb-secure-def  ( channel# -- )  >r " u:\fs.zip" " u:\fs.zd" r> #nb-secure  ;

: nb-secure   ( -- )  nb-auto-channel  #nb-secure-def  ;

[ifdef] use-nb15-precomputed
\ NANDblaster sender using thin firmware on XO-1.5, with precomputed
\ packet data.  This turns out to be useless because the packets can
\ be computed on-the-fly faster than the module can send.
: nb15-precomputed:  ( "filename" ["delay"]-- )
   false to already-go?
   safe-parse-word  ( name$ )
   safe-parse-word 2>r ( name$ r: channel$ )
   parse-word  2swap   ( delay$ name$ r: channel$ )
   2r>
   " u:\usb8388t.bin" " wlan-fw" $setenv
   " boot rom:blaster thinmac:OLPC-NANDblaster,%s %s %s" sprintf eval
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
