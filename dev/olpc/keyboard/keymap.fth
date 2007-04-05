purpose: Positions of ASCII characters on various keyboards

\ We only worry about the US ASCII characters because that is
\ the character set of the firmware.

\ US intl
\ numbers shift: !@#$%^&*()
\ numbers altgr:
\ others  shift: ~_+{}:"|<>?/
\ others  plain: `-=[];'\,./*
\ others  altgr:   ~`'~^ ."-  (unnecessary)


\ Thai: same as US ASCII
\ Arabic: same as US ASCII
\ Nigeria: same as US ASCII

\ Spanish
\ numbers shift: !"`$%&/()=
\ numbers altgr:  @# ^ \   
\ others  shift:  ? "{N*};:_>
\ others  plain: |' '[n+],.-<
\ others  altgr:       ~        (Forth doesn't use ~)

\ Portugese:
\ numbers shift: !@#$%"&*()        (same as US ASCII)
\ numbers altgr: 
\ others  shift: "_+`{ ^}<>:?
\ others  plain: '-='[ ~],.;/
\ others  altgr: NONE

\ Scan codes:
\ Numbers: 2 3 4 5 6 7 8 9 a b
\ Others: 

\ Comments show the ASCII codes for the US intl keyboard
create punct-scancodes
  \  `~        -_        =+                  Number row
  h# 29 c,  h#  c c,  h#  d c,

  \  [{        ]}                            QWER row
  h# 1a c,  h# 1b c,

  \  ;:        '"        \|                  ASDF row
  h# 27 c,  h# 28 c,  h# 2b c,

  \  ,<        .>        /?    timesdivide   ZXCV row
  h# 33 c,  h# 34 c,  h# 35 c,  h# 73 c,

\ The scancodes for the number keys are 2,3..a,b for numbers 1,2..9,0

: clone-keymap  ( -- )
   /keymap alloc-mem to oem-keymap
   oem-keymap /keymap 0 fill
   [ also keyboards ]  us  [ previous ]  oem-keymap  h# c0 move
   oem-keymap to keymap
;

: set-number-keys  ( adr len base-slot# -- )
   -rot  bounds  ?do                                  ( slot# )
      i c@  dup bl <>  if  over c!  else  drop  then  ( slot# )
      1+                                              ( slot#' )
   loop                                               ( slot# )
   drop                                               ( )
;
: shift-numbers  ( adr len -- )  h# 62 set-number-keys  ;
: altgr-numbers  ( adr len -- )  h# c2 set-number-keys  ;

: set-punct-keys  ( adr len base-slot# -- )
   keymap +                                  ( adr map-adr )
   swap  0  ?do                              ( adr map-adr )
      over i + c@  dup bl <>  if             ( adr map-adr char )
         over  punct-scancodes i + c@ +  c!  ( adr map-adr )
      else                                   ( adr map-adr char )
         drop                                ( adr map-adr char )
      then                                   ( adr map-adr )
   loop                                      ( adr map-adr )
   2drop                                     ( )
;
: plain-punctuation  ( adr len -- )      0 set-punct-keys  ;
: shift-punctuation  ( adr len -- )  h# 60 set-punct-keys  ;
: altgr-punctuation  ( adr len -- )  h# c0 set-punct-keys  ;

: es-argentina  ( -- )
   clone-keymap
   " !""`$%&/()=" shift-numbers
   "  @# ^ \   "  altgr-numbers
   " |' '[ +],.-<"  plain-punctuation
   "  ? ""{ *};:_>" shift-punctuation
   "       ~     "  altgr-punctuation
;

: pt-brazil  ( -- )
\   clone-keymap   \ We can just overwrite the US one
   " '-='[ ~],.;/"  plain-punctuation
   " ""_+`{ ^}<>:?" shift-punctuation
;
