purpose: Additional utility routines for the HD Audio driver
\ See license at end of file

\ \ Widget graph
\ \\ Traversal

' noop value do-xt
0 value do-tree-level

defer do-subtree

: #subnodes      ( -- u )     h# f0004 cmd?  h# ff and  ;
: first-subnode  ( -- node )  h# f0004 cmd?  d# 16 rshift  ;

: do-subtree-recursive  ( xt codec node -- )
    to node to codec                          ( )
    do-xt execute                             ( )
    codec  first-subnode #subnodes bounds ?do ( codec )
        do-tree-level 1 + to do-tree-level
        dup i do-subtree
        do-tree-level 1 - to do-tree-level
    loop ( codec )
    drop
;

' do-subtree-recursive is do-subtree

: do-tree  ( xt -- )  to do-xt  0 0 do-subtree ;

\ - Inspecting widgets

\ \\ Getting parameters

: config-default  ( -- c )  h# f1c00 cmd?  ;
: default-device  ( -- d )  config-default d# 20 rshift  f and  ;
: connectivity    ( -- c )  config-default d# 30 rshift  ;

: #subnodes     h# f0004 cmd?  h# ff and  ;
: first-subnode h# f0004 cmd?  d# 16 rshift  ;

: widget-type    ( -- u )  h# f0009 cmd?  d# 20 rshift f and  ;
: pin-widget?    ( -- ? )  widget-type 4 =  ;
: builtin?       ( -- ? )  connectivity 2 =  ;
: speaker?       ( -- ? )  default-device 1 =  ;
: headphone?     ( -- ? )  default-device 2 =  ;
: mic?           ( -- ? )  default-device h# a =  ;

: config-default  ( -- c )  h# f1c00 cmd?  ;
: connection-select  ( -- n )  h# f0100 cmd?  ;
: default-device  ( -- d )  config-default d# 20 rshift  f and  ;
: location        ( -- l )  config-default d# 24 rshift 3f and  ;
: color           ( -- c )  config-default d# 12 rshift  f and  ;
: connectivity    ( -- c )  config-default d# 30 rshift  ;
: connection-list  ( -- n )  f0200 cmd?  ;

: gain/mute  ( output? left? -- gain mute? )
    0 swap if  h# 2000 or  then
    swap   if  h# 8000 or  then
    h# b0000 or  cmd?
    dup h# 7f and       ( res gain )
    swap h# 80 and 0<>  ( gain mute? )
;

: .connectivity  ( -- )
    case connectivity
        0 of ." external " endof
        1 of ." unused " endof
        2 of ." builtin " endof
        3 of ." builtin/external " endof
    endcase
;

: .color  ( -- )
    case color
        1 of ." black " endof
        2 of ." grey " endof
        3 of ." blue " endof
        4 of ." green " endof
        5 of ." red " endof
        6 of ." orange " endof
        7 of ." yellow " endof
        8 of ." purple " endof
        9 of ." pink " endof
        e of ." white " endof
    endcase
;

: .location  ( -- )
    case location
        1 of ." rear " endof
        2 of ." front " endof
        3 of ." left " endof
        4 of ." right " endof
        5 of ." top " endof
        6 of ." bottom " endof
        7 of ." special " endof
    endcase
;    

: .default-device  ( -- )
    case default-device
        0 of ." line out)" endof
        1 of ." speaker)"  endof
        2 of ." HP out)"   endof
        3 of ." CD)"       endof
        4 of ." SPDIF out)" endof
        5 of ." digital other out)" endof
        6 of ." modem line side)" endof
        7 of ." modem handset side)" endof
        8 of ." line in)" endof
        9 of ." aux)" endof
        a of ." mic in)" endof
        b of ." telephony)" endof
        c of ." SPDIF in)" endof
        d of ." digital other in)" endof
        dup of ." unknown)" endof
    endcase
;

: .node  ( -- )
    do-tree-level spaces
    codec . ." / " node .
    f0200 cmd? lbsplit 4 0 do <# u# u# u#> type space loop 2 spaces
    widget-type case
        0   of ." audio output"   endof
        1   of ." audio input"    endof
        2   of ." audio mixer"    endof
        3   of ." audio selector" endof
        4   of ." pin widget (" .connectivity .color .location .default-device endof
        5   of ." power widget"   endof
        6   of ." volume knob"    endof
        7   of ." beep generator" endof
        dup of                    endof
    endcase
    cr
;

\ : in-amp-caps  ( -- u ) h# f000d cmd? ;
\ : in-gain-steps  ( -- n ) in-amp-caps  8 rshift h# 7f and  1+ ;
: in-step-size  ( -- n )  in-amp-caps  d# 16 rshift  h# 7f and  1+  ;
: in-0dB-step   ( -- n )  in-amp-caps  h# 7f and  ;
: in-steps/dB  ( -- #steps )  in-step-size 4 *  ;

: .input-amp  ( -- )
   ." gain steps: " in-gain-steps . cr
   ."  left gain:  " false true  gain/mute swap . if ." (muted)" then cr
   ." right gain:  " false false gain/mute swap . if ." (muted)" then cr
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie <luke@bup.co.nz>
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
