\ See license at end of file
purpose: Declare defered words and some primitives

hex 
headers

\ This file contains the defer words that must be filled by
\ the various dac and controller methods as things are probed
\ and discovered.

\ DAC words

defer init-hook			\ Hook to end of display-install
' noop to init-hook
defer init-dac			\ DAC initialization routine
defer reinit-dac  		\ DAC reinitialization routine
' noop to reinit-dac		\ reinit-dac is almost always null
defer idac@			\ Indexed DAC read
defer idac!			\ Indexed DAC write
defer rmr@			\ Pixel read mask read
defer rmr!			\ Pixel read mask write
defer plt@			\ Palette read
defer plt!			\ Palette write
defer rindex!			\ Read index for palette read
defer windex!			\ Write index for palatte write
defer index!			\ Index for generic IO
defer rs@			\ Read DAC RS[x] address
defer rs!			\ Write DAC RS[x]address
defer set-pclk			\ Set the pixel clock frequency
defer set-mclk			\ Set the memory clock frequency
defer pclk-stable?		\ Is the pixel clock stable?
defer mclk-stable?		\ Is the memory clock stable?

\ Controller words

defer init-controller		\ Controller programming
defer reinit-controller		\ Controller programming
' noop to reinit-controller
defer video-on			\ Generic video on word
defer ext-textmode		\ Controller-specific text mode stuff
' noop to ext-textmode

0 instance value dac-index-adr	\ Address of index register for indexed DAC
0 instance value dac-data-adr	\ Address of data register for indexed DAC

\ Mapping words

defer map-io-regs		\ Mapping of non-relocateable io space words
defer unmap-io-regs		\ Unmapping of same
defer map-frame-buffer		\ Frame buffer mapping
defer unmap-frame-buffer	\ Unmapping of same

false instance value 6-bit-primaries?	\ Indicate if DAC only supports 6bpp
-1 value io-base			\ Where pointer to io mapping is held

: pc@  ( offset -- byte )  io-base + rb@  ;
: pc!  ( byte offset -- )  io-base + rb!  ;
: pw!  ( word offset -- )  io-base + rw!  ;
: pw@  ( offset -- byte )  io-base + rw@  ;
: pl@  ( offset -- lwrd )  io-base + rl@  ;
: pl!  ( lwrd offset -- )  io-base + rl!  ;

d# 640 instance value width		\ Screen width
d# 480 instance value height            \ Screen height
8 instance value depth			\ Bits per pixel

d# 640 instance value /scanline		\ Bytes per line

: set-depth  ( depth -- )
   to depth
   \ The following is correct for framebuffers without extra padding
   \ at the end of each scanline.  Adjust /scanline for others.
   width depth *  8 /  to /scanline
;
: (set-resolution)  ( width height depth -- )
   >r  to height  to width  r> set-depth
;

: 640x480x8  ( -- )  d# 640 d# 480 8 (set-resolution)  ;
: 1024x768x8  ( -- )  d# 1024 d# 768 8 (set-resolution)  ;
: 1024x768x16  ( -- )  d# 1024 d# 768 d# 16 (set-resolution)  ;
: 1024x768x32  ( -- )  d# 1024 d# 768 d# 32 (set-resolution)  ;
: 1280x1024x8  ( -- )  d# 1280 d# 1024 8 (set-resolution)  ;
: 1280x1024x16  ( -- )  d# 1280 d# 1024 d# 16 (set-resolution)  ;
: 1280x1024x32  ( -- )  d# 1280 d# 1024 d# 32 (set-resolution)  ;

: 640-resolution  ( -- )  d# 640 d# 480 8 (set-resolution)  ;
: 1024-resolution  ( -- )  d# 1024 d# 768 8 (set-resolution)  ;

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width  encode-int " width"     property
      height encode-int " height"    property
      depth  encode-int " depth"     property
      /scanline  encode-int " linebytes" property
   else
      2drop
   then
;

: /fb  ( -- )  /scanline height *  ;	\ Size of framebuffer

\ Helper words...

: c-l@  ( adr -- l )		\ Reads a PCI config register (word)
   my-space + " config-l@" $call-parent
;

: c-l!  ( l adr -- )		\ Writes a PCI config register (word)
   my-space + " config-l!" $call-parent
;

: c-w@  ( adr -- w )		\ Reads a PCI config register (half-word)
   my-space + " config-w@" $call-parent
;

: c-w!  ( w adr -- )		\ Writes a PCI config register (half-word)
   my-space + " config-w!" $call-parent
;

: c-b@  ( adr -- b )		\ Reads a PCI config register (byte)
   my-space + " config-b@" $call-parent
;

: c-b!  ( b adr -- )		\ Writes a PCI config register (byte)
   my-space + " config-b!" $call-parent
;

: map-in  (   )			\ Calls parent's map-in method
   " map-in" $call-parent
;

: map-out  (   )		\ Calls parent's map-out method
   " map-out" $call-parent
;

\ Driver variables

\ Controllers

-1 value board
0 constant diamond			\ Diamond boards
1 constant number9			\ Number nine boards
\ 2 constant paradise			\ Paradise boards
\ 3 constant orchid			\ Orchid boards
\ 4 constant ibm-43p			\ IBM motherboard

\ Generic controller types

-1 value chip
0 constant s3				\ S3 chip set
1 constant cirrus			\ Cirrus chip set
2 constant mga				\ Matrox chip set
3 constant glint			\ Glint chip
4 constant weitek			\ Weitek chip set
5 constant n9				\ Number Nine (I-128)
6 constant ct				\ Chips and Technology

\ Specific controller types

-1 value variant
0  constant s3-928
1  constant s3-964			\ Used in GXEPro
2  constant s3-864			\ Used in GXE
3  constant s3-868			\ Used in Motion 531
4  constant s3-968			\ Used in Motion 771 & big stealth 64
5  constant s3-trio64			\ Used in Motion 330 & small stealth 64
6  constant s3-virge			\ Yet another version of stealth
10 constant gd5434			\ Used in Kelvin-64
11 constant gd5430			\ Used in Speedstar
12 constant gd5436			\ Used in Cirrus eval board
20 constant storm			\ Used in Matrox Millenium (4MB)
21 constant storm2			\ The 2MB version of above
30 constant 300sx			\ Glint 300SX
40 constant p9100			\ Weitek P9100
50 constant i128			\ Imagine 128
60 constant ct6555x			\ Chips and Technology 6555x

\ Safety Valve
false value safe?			\ A safety valve so we don't hang 
					\ on unknown hardware

: diamond?    board diamond =  ;
: number9?    board number9 =  ;
\ : paradise?   board paradise =  ;
\ : orchid?     board orchid =  ;
\ : ibm-43p?    board ibm-43p =  ;

: s3?	   chip s3     =  ;		\ True if chip set is S3 based
: cirrus?  chip cirrus =  ;		\ True if chip set is Cirrus based
: mga?     chip mga    =  ;		\ True if chip set is Matrox
: glint?   chip glint  =  ;		\ True if chip set is Glint
: weitek?  chip weitek =  ;		\ True if chip set is Weitek
: n9?      chip n9     =  ;		\ True if chip set is Number 9
: ct?      chip ct     =  ;		\ True if chip set is Chips and Technology

: s3-928?    variant s3-928    =  ;	\ The following tell us which variant
: s3-964?    variant s3-964    =  ;
: s3-864?    variant s3-864    =  ;
: s3-868?    variant s3-868    =  ;
: s3-968?    variant s3-968    =  ;
: s3-trio64? variant s3-trio64 =  ;
: s3-virge?  variant s3-virge  =  ;
: gd5430?    variant gd5430    =  ;
: gd5434?    variant gd5434    =  ;
: gd5436?    variant gd5436    =  ;
: storm?     variant storm     =  ;
: storm2?    variant storm2    =  ;
: 300sx?     variant 300sx     =  ;
: p9100?     variant p9100     =  ;
: i128?      variant i128      =  ;

: .driver-info   ( -- )  ;		\ Chained driver info

: probe-dac  ( -- )  ;			\ Chained dac prober

\ Apple has a bug we sometimes need to deal with. We need to deal with 
\ the bug if this driver (or pieces of it) is used to build an FCode image
\ that will be placed into an FCcode ROM on a PCI card. The following
\ two methods are provided to help deal with the bug. The bug that we
\ are dealing with here is that when "map-in" is called for PCI devices,
\ Apples behave as if the non-relocatable bit is set and there fore treats
\ phys.lo and phys.mid as absolute addresses rather than offsets.

\ Flag is true if the parent's map-in method doesn't work with
\ relocatable addresses.

: map-in-broken?  ( -- flag )
   \ Look for the method that is present when the bug is present
   " add-range"  my-parent  ihandle>phandle   ( adr len phandle )
   find-method  dup  if  nip  then            ( flag )  \ Discard xt if present
;

\ Return phys.lo and phys.mid of the address assigned to the PCI base address
\ register indicated by phys.hi .

: get-base-address  ( phys.hi -- phys.lo phys.mid phys.hi )

   " assigned-addresses" get-my-property  if   ( phys.hi )
      ." No address property found!" cr
      0 0 rot  exit                            \ Error exit
   then                      ( phys.hi adr len )

   rot >r                    ( adr len )  ( r: phys.hi )
   \ Found assigned-addresses, get address
   begin  dup  while         ( adr len' )  \ Loop over entries
      decode-phys            ( adr len' phys.lo phys.mid phys.hi )
      h# ff and  r@ h# ff and  =  if  ( adr len' phys.lo phys.mid )  \ This one?
         2swap 2drop         ( phys.lo phys.mid )          \ This is the one
         r> exit             ( phys.lo phys.mid phys.hi )
      else                   ( adr len' phys.lo phys.mid ) \ Not this one
         2drop               ( adr len' )
      then                   ( adr len' )
      decode-int drop decode-int drop        \ Discard boring fields
   repeat
   2drop                     ( )

   ." Base address not assigned!" cr

   0 0 r>                    ( 0 0 phys.hi )
;
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
