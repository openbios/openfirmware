\ See license at end of file
purpose: Registers

hex
headers

d# 128 constant /audio-reg
d#  32 constant /smi-reg
d#  16 constant /ide-reg
d# 1024 4 * constant /video-reg

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int      0 +int

\ I/O space registers (make them non-relocatable)
0 0  my-space  8100.0010 + encode-phys encode+  0 +int  /audio-reg  +int
0 0  my-space  8100.0014 + encode-phys encode+  0 +int  /smi-reg  +int
0 0  my-space  8100.0018 + encode-phys encode+  0 +int  /ide-reg  +int

\ Memory mapped I/O space registers
0 0  my-space  8200.001c + encode-phys encode+  0 +int  /video-reg  +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

0 value audio-base
0 value smi-base
0 value ide-base
0 value video-base

: map-in   " map-in"  $call-parent  ;
: map-out  " map-out" $call-parent  ;

: map-audio-reg  ( -- )
   0 0  my-space h# 0100.0010 +  /audio-reg map-in  to audio-base
;
: map-smi-reg  ( -- )
   0 0  my-space h# 0100.0014 +  /smi-reg   map-in  to smi-base
;
: map-ide-reg  ( -- )
   0 0  my-space h# 0100.0018 +  /ide-reg   map-in  to ide-base
;
: map-video-reg  ( -- )
   0 0  my-space h# 0200.001c +  /video-reg map-in  to video-base
;
: map-regs  ( -- )
   map-audio-reg
   map-smi-reg
   map-ide-reg
   map-video-reg
;
: unmap-regs  ( -- )
   audio-base  /audio-reg  map-out
   smi-base    /smi-reg    map-out
   ide-base    /ide-reg    map-out
   video-base  /video-reg  map-out
;

: reg-l@  ( register chipbase -- l )  + rl@  ;
: reg-l!  ( l register chipbase -- )  + rl!  ;
: reg-w@  ( register chipbase -- w )  + rw@  ;
: reg-w!  ( w register chipbase -- )  + rw!  ;
: reg-b@  ( register chipbase -- b )  + rb@  ;
: reg-b!  ( b register chipbase -- )  + rb!  ;

: audio-l@  ( register -- l )  audio-base reg-l@  ;
: audio-l!  ( l register -- )  audio-base reg-l!  ;
: audio-w@  ( register -- l )  audio-base reg-w@  ;
: audio-w!  ( l register -- )  audio-base reg-w!  ;
: audio-b@  ( register -- l )  audio-base reg-b@  ;
: audio-b!  ( l register -- )  audio-base reg-b!  ;

: smi-l@  ( register -- l )  smi-base reg-l@  ;
: smi-l!  ( l register -- )  smi-base reg-l!  ;
: smi-w@  ( register -- l )  smi-base reg-w@  ;
: smi-w!  ( l register -- )  smi-base reg-w!  ;
: smi-b@  ( register -- l )  smi-base reg-b@  ;
: smi-b!  ( l register -- )  smi-base reg-b!  ;

: ide-l@  ( register -- l )  ide-base reg-l@  ;
: ide-l!  ( l register -- )  ide-base reg-l!  ;
: ide-w@  ( register -- l )  ide-base reg-w@  ;
: ide-w!  ( l register -- )  ide-base reg-w!  ;
: ide-b@  ( register -- l )  ide-base reg-b@  ;
: ide-b!  ( l register -- )  ide-base reg-b!  ;

: video-l@  ( register -- l )  video-base reg-l@  ;
: video-l!  ( l register -- )  video-base reg-l!  ;



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
