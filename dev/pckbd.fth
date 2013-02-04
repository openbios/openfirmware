\ See license at end of file
purpose: Package methods for 80C42 keyboard controller

\ " us" d# 16 config-string pc-keyboard-type

hex
headerless

my-space " reg" integer-property
" keyboard"  device-name

" pnpPNP,303" " compatible" string-property

" keyboard" device-type

: kbdtest ;

0 value #queued
d# 4 buffer: ascii-queue

\ Keyboard command constants
\  ed constant set-leds
\  ee constant echo
\  f0 constant set-scan-codes
\  f2 constant read-id
\  f4 constant enable-scan
\  f5 constant default-disable
\  f6 constant default-enable
\  ff constant reset

\ Keyboard status constants
\  fa constant ack
\  aa constant bat-pass
\  fc constant bat-fail
\  ee constant echo
\  fe constant resend

\ Various keyboard flags
false value check-abort?	\ True to abort on CTRL-BREAK
0 value last-scan		\ Memory for detecting up transitions

false value keyboard-probed?      \ Used to identify whether keyboard methods
				  \ have already been installed
false value keyboard-present?     \ Nonzero if the keyboard is operational
false value locked?		  \ Interrupt lockout for get-scan

: lock    ( -- )  true  to locked?  ;
: unlock  ( -- )  false to locked?  ;

\ Scan code queue
d# 100 constant /q

variable head  0 head !
variable tail  0 tail !
/q dup buffer: q
1-     value   q-end

: init-q  ( -- )  0 head !  0 tail !  q drop  /q 1- to q-end  ;
: inc-q-ptr  ( pointer-addr -- )
   dup @ q-end >=  if  0 swap !  else  /c swap +!  then
;

: enque  ( new-entry -- )
   tail @  head @  2dup >  if  - q-end  else  1-  then  ( new-entry tail head )
   <>  if  q tail @ ca+ c!  tail inc-q-ptr  else  drop  then
;

: deque?  ( -- false | entry true )
   lock
   head @  tail @  <>  if
      q head @ ca+ c@   head inc-q-ptr  true
   else
      false
   then
   unlock
;

false value shift?		\ True if the shift key is down
false value ctrl?	  	\ True if the ctrl key is down
false value mfii?               \ True if MF II extended keys
false value alt-gr?		\ True if the AltGr key is down
-1 value dead-accent            \ The dead accent index (0-5) or -1

0 value led-state
: numlk?        ( -- flag )  led-state 2 and  0<>  ;
: caps-lock?    ( -- flag )  led-state 4 and  0<>  ;
: scroll-lock?  ( -- flag )  led-state 1 and  0<>  ;

: init-data  ( -- )
   false to keyboard-present?
   false to shift?   false to ctrl?
   0 to last-scan
   init-q
;   

\ Frequently-used interfaces to parent (8042 controller) routines

: get-data   ( -- data | -1 )  " get-data" $call-parent  ;
: get-data?  ( -- false | data true )  " get-data?" $call-parent  ;
: put-get-data  ( cmd -- data | -1 )  " put-get-data" $call-parent  ;

: clear-out-buf  ( -- )  " clear-out-buf" $call-parent  ;

: timed-read  ( #ms -- true | data false )
   0  do
      get-data?  if  unloop false exit  then
      1 ms
   loop
   true
;

0 value kbd-debug?

\ This is fairly complicated to handle several possibilities.
\ In the usual case, where the response is ACK (fa), we return true on the top
\ Another case is a RETRY (fe) response - then we return "false false" so the
\ caller will continue to retry as long as we keep seeing RETRY.
\ Bytes that are neither fa nor fe are silently discarded.
\ If we timeout without seeing either fa or fe, we return "true false" so the
\ caller will retry a limited number of times before giving up.

: got-ack?  ( -- true | timeout? false )
   begin
      \ No response - retry once
      d# 50 timed-read  if  true false exit  then  ( data )
      case
         h# fa of        true  exit  endof  \ ACK - exit without retry
         h# fe of  false false exit  endof  \ RETRY - retry as long as we keep getting fe
         \ discard other characters
      endcase
   again
;

: cmd  ( cmd -- )
   1  begin                                 ( cmd #retries )
      over  " put-data" $call-parent        ( cmd #retries )
      got-ack?  if  2drop exit  then        ( cmd #retries timeout? )

      \ Decrease the retry count if got-ack? timed out
      \ Otherwise got-ack? saw a RETRY response, in which case
      \ we retry without decrementing the count
      if  1-  then                          ( cmd #retries )

   dup 0<  until                            ( cmd #retries )

   drop                                     ( cmd )
   kbd-debug?  if                           ( cmd )
      ." Keyboard cmd " . ." failed" cr     ( )
   else                                     ( cmd )
      drop                                  ( )
   then                                     ( )
;

headers

\ Despite the manual's claim that this command can be executed at any time,
\ experience has shown that it does not work reliably.  Executing
\ cntlr-selftest, test-intf and reset seem to prepare the system.
\ kbd-reset (at least sometimes) is not sufficient preparation.
: set-scan-set  ( scan-set -- )  f0 cmd cmd  ;

\ The return value is:
\   1, 2, 3	Scan set 1, 2, or 3, h#40 bit in the 8042 cmd register clear
\   43		Scan set 1           h#40 bit set
\   41		Scan set 2           h#40 bit set
\   3f		Scan set 3           h#40 bit set
\ When the h#40 bit is set, the 8042 translates scan set 2 coming from the
\ keyboard to scan set 1 (when read from the 8042).  One might suspect from
\ the above encodings that it might also translate scan set 1 from the keyboard
\ into scan set 3.

: get-scan-set  ( -- scan-set )  lock  0 set-scan-set  get-data  unlock  ;

\ Re-initialize the keyboard and controller with the following:
\
\ 1.    Disable keyboard interface.
\ 2.	Perform controller self-test.  Report an error on failure.
\       (Selftest re-enables keyboard interface.)
\ 3.	Perform keyboard interface test.  Report an error on failure.
\ 4.	Reset the keyboard which results in the selection of Scan Set 2.  Report
\	an error on failure.
\ 5.	Perform a keyboard echo.  Report an error on failure.
\ 6.	Flash the three LEDs.

: default-disable-kbd  ( -- )  h# f5 cmd  ;
: enable-scan  ( -- )  h# f4 cmd  ;

\ Empirically, the delays help some keyboards to pass the echo test
: echo?  ( -- failed-echo? )
   d# 32 ms  h# ee put-get-data h# ee <>  d# 32 ms
;
: set-leds  ( led-mask -- )  lock  dup to led-state h# ed cmd cmd  unlock  ;
: toggle-leds  ( led-mask -- )  led-state xor  set-leds  ;

: kbd-reset  ( -- failed-reset? )
   lock
   \ Send kbd reset command
   h# ff cmd
   get-data  h# aa <>
   unlock
;

: do-esc  ( char -- ESC )
\   ascii-queue c!  ascii [ ascii-queue 1+ c!  2 to #queued   h# 1b  ( ESC )
   ascii-queue c!  1 to #queued  h# 9b  ( Unicode-CSI )
;
: do-func  ( char -- ESC )
   ascii-queue c!  ascii O ascii-queue 1+ c!  2 to #queued  h# 9b
;
\ The following keymaps map scan codes to ASCII codes.  In those cases
\ where the scan code represents a key for which there is no ASCII equivalent,
\ the table contains a 0 byte.  This use of 0 does not prevent the generation
\ ASCII NUL (whose numerical value is 0) because control characters are
\ mostly generated by masking bits off of printable entries.  (The only
\ exceptions are Tab, BackSpace, Escape, and Return, which are the only
\ control characters that are directly generated by single keys on a
\ PC keyboard.)

\ "Syntactic sugar" to make keymaps easier to read and write
: ch  ( "char" -- )  char c,  ;
: xx  ( -- )  0 c,  ;

0 value keymap  ( -- adr )
h# 60 3 * 1+ constant /keymap  \ The maximum size of a keymap

vocabulary keyboards

also keyboards definitions
fload ${BP}/dev/keymaps/pc/us.kbm
previous definitions

: ?set-property  ( value$ name$ -- )
   2swap 2over get-my-property  0=  if   ( name$ value$ name$ adr1 len1 )
      get-encoded-string  2over $=  if   ( name$ value$ )
         2drop 2drop exit                ( )
      then                               ( name$ value$ )
   then                                  ( name$ value$ )
   encode-string 2swap property          ( )
;
0 instance value oem-keymap
: (set-keyboard)  ( adr len xt -- )
   -rot                                              ( xt adr len )
   " keyboard-type" ?set-property                    ( xt )
   execute                                           ( adr )
   dup 2 " language" ?set-property                   ( adr )
   2+ to keymap                                      ( )
;
: set-keyboard  ( adr len -- )
   2dup ['] keyboards $vfind  0=  if                       ( adr len )
      2drop " us" [ also keyboards ] ['] us  [ previous ]  ( adr' len' xt )
   then                                                    ( adr len xt )
   (set-keyboard)
;
: ?free-keymap  ( -- )
   oem-keymap  if  oem-keymap  /keymap  free-mem  then
   0 to oem-keymap
;

[ifdef] olpc
[ifndef] demo-board

[ifdef] trust-ec-keyboard
: ?olpc-keyboard  ( -- )  true to keyboard-present?  ;
[else]
\ For the ENE keyboard controller we have to tell the EC to use
\ a different internal mapping table.  OLPC switched from an
\ ALPS to an ENE controller in late 2007.
: olpc-set-ec-keymap  ( -- )
   h# f2 cmd

   \ Keyboards return the ID sequence  ab XX
   d# 50 timed-read  if  exit  then  ( id1 )
   h# ab <>  if  exit  then

   \ The ENE keyboard controller returns  ab 41
   d# 50 timed-read  if  exit  then  ( id2 )
   h# 41 <>  if  exit  then
   
   \ This looks like an ENE controller, so flip the mapping table
   h# f7 cmd
;   

: ?olpc-keyboard  ( -- )
    " enable-intf" $call-parent
    begin  d# 50 timed-read 0=  while
       drop
       true to keyboard-present?
       olpc-set-ec-keymap
       exit
    repeat
    keyboard-present?  if  exit  then
    kbd-reset 0= to keyboard-present?

    \ Try resetting the keyboard
    kbd-reset 0= to keyboard-present?
    keyboard-present?  if  olpc-set-ec-keymap  then
;
[then]

fload ${BP}/cpu/x86/pc/olpc/keymap.fth
[then]
[then]

: choose-type  ( -- )
   my-args  dup  if
      [char] , left-parse-string  2swap 2drop  ( $ )
      set-keyboard
      exit
   else
      2drop
   then

   " pc-keymap" $getenv  0=  if    \ Property exists ( adr len )
      decode-string " keyboard-type" ?set-property   ( adr' len' )
      2 decode-bytes " language" ?set-property       ( adr' len' )
      ?free-keymap
      /keymap alloc-mem to oem-keymap                ( adr' len' )
      oem-keymap /keymap 0 fill                      ( adr' len' )
      oem-keymap swap move                           ( )
      oem-keymap to keymap                           ( )
      exit
   then

[ifdef] olpc-keymap?
   olpc-keymap?  if  exit  then
[then]

   " us" set-keyboard
\    pc-keyboard-type set-keyboard
;

: map?  ( scancode map-adr -- scancode false | char true )
   >r
   dup  r@ c@  r@ 1+ c@  between  if      ( scancode )
      r@ c@ -  r> 2+ + c@  true           ( char true )
   else                                   ( scancode )
      r> drop false
   then
;
   
\ The escape sequences implied by the following two tables are as
\ defined by the Windows NT "Portable Boot Loader" (formerly known
\ as ARC firmware) spec. They were subsequently adopted in some PowerPC
\ Open Firmware bindings. 
create move-map  90 c,  9a c,
   ch @   \ Insert
   ch K   \ End
   ch B   \ Down
   ch /   \ Page Down
   ch D   \ Left
   ch 5   \ bogus
   ch C   \ Right
   ch H   \ Home
   ch A   \ Up
   ch ?   \ Page Up
   ch P   \ Delete  (use DEL, 7f)

create func-map  81 c,  8c c,
   ch P   \ F1
   ch Q   \ F2
   ch W   \ F3
   ch x   \ F4
   ch t   \ F5
   ch u   \ F6
   ch q   \ F7
   ch r   \ F8
   ch p   \ F9
   ch M   \ F10
   ch A   \ F11
   ch B   \ F12

: get-special-key  ( char -- false | ASCII-code true )
   func-map  map?  if  do-func true  exit  then  
   move-map  map?  if  do-esc  true  exit  then
   ?dup 0<>
;

\ Handle reports of keys already down.
\ Also, some keyboards send an unsolicited "aa" code after power is applied,
\ indicating successful completion of the keyboard's internal selftest, which
\ we ignore.

0 value ctrl-down?
0 value alt-down?
0 value initial-key

\ These scancodes are from set 1.
: handle-initial-scan  ( scancode -- )
   case
      h# 1d  of  true  to ctrl-down?   endof
      h# 38  of  true  to alt-down?    endof
      h# 9d  of  false to ctrl-down?   endof
      h# b8  of  false to alt-down?    endof
      ( default )
      dup  h# 60 <=  if  dup keymap 1+ + c@  to initial-key  then
   endcase
;

: clear-state  ( -- )
   false to ctrl-down?
   false to alt-down?
   ff    to initial-key
   " us" set-keyboard
\   choose-type
;
: consume  ( -- )   begin  5 timed-read  0=  while  drop  repeat  ;

: get-initial-state  ( -- )
   d# 200 ms      \ Give the keyboard time to respond

   \ 5 ms is less than the standard auto-repeat rate
   begin  5 timed-read  0=  while  handle-initial-scan  repeat

   default-disable-kbd	\ Clear last typematic key, if any
   consume
;

: initial-key?  ( -- false | char true )
   initial-key ff =  if  false exit  then

   \ 5 and 6 are the codes for BREAK and CTRL-BREAK, respectively
   \ -1 as a return value means "break"
   initial-key  5 6 between  if  -1 true exit  then

   \ 81..8c are the function keys F1..F12
   initial-key  h# 81  h# 8c between  if  initial-key true  exit  then

   alt-down?  if  initial-key true exit  then
   false
;

: reset  ( -- )
   init-data
   clear-state
[ifdef] ?olpc-keyboard
   ?olpc-keyboard
[else]
   get-initial-state

   \ Test the keyboard interface clock and data lines
   " test-lines" $call-parent  if  false to keyboard-present? exit  then
   consume

   kbd-reset  if
      false to keyboard-present?
   else
      get-initial-state     \ Handle reports of keys already down

      echo?  dup 0= to keyboard-present?  if
         ." Failed keyboard echo test" cr
      then

\     7 set-leds  d# 100 ms  0 set-leds
   then

   \ Leave the keyboard in scan set 2 (its default state), but also leave
   \ the 8042 in the mode where it translates to scan set 1.

   keyboard-present?  if  enable-scan  then
[then]
   true to keyboard-probed?
;

\ Without doing unnecessary testing, put the keyboard into a known state.
\ This routine is used after watchdog timer resets and other conditions
\ that leave the system in an unknown state.

: restore  ( -- )
   init-data
   kbd-reset 0= to keyboard-present?
;
defer scan-handled?
' false to scan-handled?
headerless
: check-abort  ( scan-code -- flag )  \ Ctrl-break pressed?
   check-abort?  if
      \ Ctrl-break does not auto-repeat, so we needn't worry about
      \ multiple down transitions
      dup h# c6 =  if				\ Ctrl-break?
         last-scan h# e0 =
      else
         false
      then
   else
      false
   then
   swap to last-scan
;

: get-scan  ( -- )
   locked?  if  exit  then

   lock
   begin
      get-data?
   while                                     ( scan-code )
      \ In the following code, we must be careful to unlock the
      \ queue before calling user-abort, because a timer interrupt
      \ can occur at any time after user-abort is executed.
      dup check-abort  if                    ( scan-code )
         drop
         unlock  user-abort
         \ Wait here for long enough to ensure that an alarm timer tick
         \ will happen if it is going to happen.  This is the safest
         \ solution I have found to the following problem: If the abort
         \ sequence is detected while polling the keyboard from the
         \ application level (i.e. not from the alarm handler), then
         \ the alarm handler is likely to sense it a little later,
         \ perhaps in the middle of deque? .  Aborting in the middle of
         \ of deque? is bad, because it leaves the lock set and potentially
         \ leaves the queue pointers and/or stateful hardware in an
         \ inconsistent state.  One solution would be to avoid calling
         \ deque after calling user-abort, but that would hang the driver
         \ if the alarm tick is turned off.
         d# 20 ms
         exit
      then                                         ( scan-code )
      scan-handled?  if  drop  else  enque  then   ( )
   repeat
   unlock
;

: set-port  ( port# -- )  " set-port" $call-parent  ;

variable kbd-refcount
: +refcnt  ( n -- )  kbd-refcount +!  ;
0 kbd-refcount !

headers
: open  ( -- okay? )
   my-space set-port
   kbd-refcount @  if  1 +refcnt  true exit  then
   unlock
   keyboard-present?  if  clear-out-buf  else  reset  then
   keyboard-present?  0=  if  false exit  then
   choose-type
   ['] get-scan d# 10 alarm
   1 +refcnt
   true
;

: close  ( -- )
   -1 +refcnt  kbd-refcount @  if  exit  then
   ?free-keymap
   ['] get-scan  0 alarm
;

: install-abort  ( -- )  true to check-abort?  ;
: remove-abort  ( -- )  false to check-abort?  ;

headerless
: >keycode  ( scan-code -- char )
   keymap c@ 2 >  alt-gr?  and  if
      h# c0 +
   else
      shift?  if  h# 60 +  then
   then
   keymap 1+ +  c@
;

\ Schema for Latin-1 accents:
\ lower-case is c0+x, upper case is e0+x
\ letter   grave  acute circumflex tilde diaresis  ring  .e  slash  cedilla obl
\    A     c0     c1    c2         c3    c4        c5    c6
\    E     c8     c9    ca         cb
\    I     cc     cd    ce         cf
\    O     d2     d3    d4         d5    d6				    d8
\    U     d9     da    db               dc
\    Y            dd
\    y                                   ff
\    C                                                                 c7
\    N                             d1

\    ETH d0  eth f0
\    multiply d7  division f7
\    oslash f8
\    THORN de  thorn fe
\    ssharp df

\ grave: vowel-base + 0
\ acute: vowel-base + 1
\ circumflex: vowel-base + 2
\ tilde: vowel-base + 3       (but bogus for u)
\ diaresis: vowel-base + (3 for u, 4 for a and o)

\ Search for a match for "byte" in the "key" position of the table at
\ "table-adr". If a match is found, return the corresponding "value" byte
\ and true.  Otherwise return the argument byte and false.  The table
\ consists of pairs of bytes - the first byte of the pair is "key" and
\ the second is "value".  The end of the table is marked by a 0 byte in
\ the "key" position.
: translate-byte ( byte table-adr -- byte false | byte' true )
   begin  dup c@  while                             ( char adr )
      2dup c@ =  if  nip 1+ c@ true  exit  then     ( char adr )
      2+                                            ( char adr' )
   repeat                                           ( char adr' )
   drop false
;

create dead-punctuation
\ base  grave  acute  circumflex  tilde  diaeresis  cedilla
  ch /   xx     xx        ch |     xx      xx         xx
  bl c,  ch `   ch '      ch ^     ch ~    a8 c,      xx     \ diaeresis
  ch 0   xx     xx        b0 c,    xx      xx         xx     \ degree
  ch 1   xx     xx        b9 c,    xx      xx         xx     \ onesuperior
  ch 2   xx     xx        b2 c,    xx      xx         xx     \ twosuperior
  ch 3   xx     xx        b3 c,    xx      xx         xx     \ threesuperior
  ch .   xx     xx        b7 c,    xx      xx         xx     \ periodcentered
  ch !   xx     xx        a6 c,    xx      xx         xx     \ brokenbar
  ch -   xx     xx        af c,    xx      xx         ac c,  \ macron, notsign
  ch _   xx     xx        af c,    xx      xx         xx     \ macron
  ch '   xx     b4 c,     xx       xx      xx         xx     \ acute
  ch ,   xx     xx        xx       xx      xx         b8 c,  \ cedilla
  ch "   xx     xx        xx       xx      a8 c,      xx     \ diaeresis
  ch C   xx     xx        xx       xx      xx         c7 c,  \ Ccedilla
  ch c   xx     xx        xx       xx      xx         e7 c,  \ ccedilla
  0 c,

\ Positions of accented vowels within the ISO-Latin-1 character encoding
create vowel-bases
ch A  c0 c,  ch E  c8 c,  ch I  cc c,  ch O  d2 c,  ch U  d9 c,
ch a  e0 c,  ch e  e8 c,  ch i  ec c,  ch o  f2 c,  ch u  f9 c,
0 c,

create dead-map  h# 10 c,  h# 15 c,
   0 c,  \ 10: dead_grave      - index 0
   1 c,  \ 11: dead_acute      - index 1
   2 c,  \ 12: dead_circumflex - index 2
   3 c,  \ 13: dead_tilde      - index 3
   4 c,  \ 14: dead_diaeresis  - index 4
   5 c,  \ 15: dead_cedilla    - index 5

: ?dead-accent  ( char -- char' )
   dead-accent  -1  =  if  exit  then

   \ First search the punctuation table
   dead-punctuation  begin  2dup c@  dup  while   ( char adr char char' )
      =  if                                       ( char adr )
         dead-accent + c@                         ( char char'|0 )
         ?dup  if  nip  then   exit               ( char|char' )
      then                                        ( char adr )
      7 +                                         ( char adr' )
   repeat                                         ( char adr char char' )
   3drop                                          ( char )

   \ If it isn't in the punctuation table, try the vowel table, but
   \ not if the dead accent is cedilla (cedilla doesn't apply to vowels)
   dead-accent 5 =  if  drop exit  then           ( char )

   \ Unlike the other diaeresis vowels, u diaeresis is offset 3 instead of 4
   dup [char] u =  dead-accent 4  =  and  if      ( char )
      dead-accent 1- to dead-accent               ( char )
   then                                           ( char )
   vowel-bases translate-byte  if  dead-accent +  then    ( char' )
;

create keypad-map  h# 90 c,  h# 9a c,
   ch 0   \ 0/Insert
   ch 1   \ 1/End
   ch 2   \ 2/Down
   ch 3   \ 3/PageDown
   ch 4   \ 4/Left
   ch 5   \ 5/<nothing>
   ch 6   \ 6/Right
   ch 7   \ 7/Home
   ch 8   \ 8/Up
   ch 9   \ 9/PageUp
   ch .   \ ./Del

\ Exchange the codes for the two symbol sets of the numeric keypad
\ if NumLock is on.
: ?numkey  ( char -- char' )
   \ The mfii? 0= clause prevents the non-keypad Delete key from being
   \ affected by NumLock.
   numlk? mfii? 0= and  if                 ( char )
      keypad-map map?  if  exit  then      ( char )
   then
;

: ?caps  ( ASCII -- ASCII' )
   caps-lock?  if
      \ Knock off the case bit so we can test fewer ranges
      dup  h# 20 invert and                  ( ASCII upc-ASCII )

      \ In the ASCII range, the alphabetic character are in the range A-Z
      dup  [char] A  [char] Z  between       ( ASCII upc-ASCII flag )

      \ In the ISO-Latin-1 range, the alphabetic characters are in the range
      \ 0xc0-0xde, except for d7 which is multiply; its conjugate f7 is
      \ divide.  df is sharp; its conjugate ff is ydiaeresis.
      over h# c0  h# de  between  or         ( ASCII upc-ASCII flag' )
      swap  h# d7 <>  and  if                ( ASCII )
         h# 20 xor                           ( ASCII' )
      then                                   ( ASCII' )
   then                                      ( ASCII' )
;
: ascii?  ( scancode -- flag )  h# 7f and  h# 20 h# 7f between  ;

: ?ctrl?  ( char -- char false | char' true )
   ctrl?  if                                ( char )
      dup  h# 40 h# 7f between  if  h# 1f and  true  exit  then
   then
   false
;
: clear-accent  ( -- )
   \ If we just turned on the dead-accent variable (as indicated by the
   \ bias of 10), remove the bias.  Otherwise zap it.
   dead-accent  h# 10 >  if  h# 10 -  else  -1  then  to dead-accent
;
: get-ascii  ( scan-code -- false | ASCII-code true )
   >keycode                                         ( char )
   ?numkey                                          ( char' )

   dead-map map?  if                                ( index )
      \ Set dead-accent with a bias so it won't be cleared when we exit
      h# 10 + to dead-accent false exit             ( false )
   then                                             ( char )

   dup ascii?  if                                   ( char )
      ?ctrl?  if  true exit  then                   ( char )
      ?caps ?dead-accent  true                      ( ASCII true )
   else  \ No ASCII code equivalent	    	    ( scan char )
      get-special-key                               ( false | ASCII true )
   then                                             ( false | ASCII true )
;

create mode-map  01 c,  06 c,
   00 c,  \ Shift
   01 c,  \ Control
   02 c,  \ Alt
   03 c,  \ Caps_Lock
   04 c,  \ Num_Lock
   05 c,  \ Scroll_Lock

: modifier?  ( down? scan -- true | down? scan false )
   dup keymap 1+ + c@  mode-map  map?  if       ( down? scan char )
      nip                                       ( down? char )
      case 
         0  of  mfii?  if  drop  else  to shift?  then  endof   \ Shift
         1  of  to ctrl?                                endof   \ Ctrl
         2  of  mfii? and  to alt-gr?                   endof   \ Alt or AltGr
         3  of  scroll-lock?  if	\ If ScrollLock is on ...
                   to ctrl?		\ ... treat the CapsLock key like Ctrl
                else			\ Otherwise give it ...
                   4 and toggle-leds	\ ... the normal CapsLock function
                then                                    endof   \ Caps Lock
         \ Pause is encoded as E1, 1D (CTRL), 45 (NUMLOCK)
         \ CTRL/Break is encoded as 1D (CTRL), E0 (MF II), 46 (ScrollLock)
         \ We filter out those modified locks to sense the real locks.
         4  of  2 and  ctrl? 0= and  toggle-leds        endof   \ Num Lock
         5  of  1 and  mfii? 0= and  toggle-leds        endof   \ Scroll Lock
         ( down? scan )  nip
      endcase
      true
   else                                         ( down? scan char )
      drop false                                ( down? scan false )
   then
;
: (scancode->char)  ( scan-code -- false | ASCII-code true )  \ Next ASCII code
   \ Split the scancode into the up/down indicator and the key identifier
   h# 80 /mod 0=  swap                           ( down? scan )
	
[ifdef] ?multkey  ?multkey  [then]

   \ Exit if the scancode is one that is never used for ASCII characters
   dup h# 60 >=  if  2drop  false  exit  then    ( down? scan )

   \ Handle modifiers like shift, ctrl, etc.
   modifier?  if  false exit  then               ( down? scan )

   \ We have handled all the mode keys.  For the rest of the keys,
   \ we can ignore the up transition.
   swap  0= if  drop false exit  then            ( scan )

   \ Try to translate the scancode into a one or more ASCII characters
   get-ascii                                     ( false | ASCII true )
   clear-accent                                  ( false | ASCII true )
;
: scancode->char  ( scan-code -- false | ASCII-code true )  \ Next ASCII code
   \ If the scancode is the keyboard escape prefix, set the MF II flag
   \ for use in processing the next scancode.
   dup h# e0 =  if  true to mfii?  drop false exit  then

   \ Otherwise, leave the MF II flag at its previous value while
   \ decoding this scancode, then clear it before returning.

   (scancode->char)                     ( false | ASCII true )

   false to mfii?                       ( false | ASCII true )
;

0 instance value time-limit
headers
: get-scancode  ( msecs -- false | scancode true )
   get-msecs + to time-limit
   begin
      get-scan  deque?  if  true exit  then
      get-msecs time-limit - 0>=
   until
   false
;

headerless
: getkey  ( -- ASCII-char true | false )
   #queued  if  #queued 1- dup to #queued  ascii-queue + c@  true exit  then
   begin
      get-scan  deque?  0=  if  false exit  then   ( scancode )
   scancode->char  until     ( ASCII-char )
   true
;

[ifdef] fix-keyboard
\ keyboard-owner: 0 firmware  1 client   2 firmware,using client's scan set
0 value keyboard-owner
0 value client-scan-set
: fw-scan-set  ( -- )
   keyboard-owner 1 =  if
      get-scan-set to client-scan-set
      client-scan-set  h# f and  1  =  if
         2 to keyboard-owner		\ We can use the client's scan set
      else
         0 to keyboard-owner		\ The firmware scan set is in use
         \ The client is using a scan set other than 1, so we switch
         \ it to set 1.  If translation is off, we tell the keyboard to
         \ send set 1; otherwise we tell the keyboard to send set 2,
         \ and let the 8042 translate it to 1.  This minimizes the
         \ amount of work we must do.
         client-scan-set  3  <=  if  1  else  2  then  lock set-scan-set unlock
      then
   then
;

\ Restore the scan set to whatever the client was using
: entering-client  ( -- )
   keyboard-owner  0=  if
      client-scan-set ?dup  if
         dup  3 >  if   ( scan-set:1,2,3,43,41,3f )
            \ Translation is on, so we have to account for the translation
            \ 43 -> 1  41 -> 2  3f -> 3
            h# 45 swap - 2/
         then                            ( kbd-scan-set:1,2,3 )
         lock set-scan-set unlock
      then
   then
   1 to keyboard-owner
;

[then]


headers
\ Search the keyboards vocabulary for an entry that contains the
\ given string in its language field.
: set-language  ( adr len -- flag )
   2 <>  if  drop false  exit  then                ( adr )
   ['] keyboards  follow  begin  another?  while   ( adr anf )
      2dup  name> >body  2 comp  0=  if            ( adr anf )
         dup name>string rot name> (set-keyboard)  ( adr )
         drop  true exit                           ( flag )
      then                                         ( adr anf )
   repeat                                          ( adr anf )
   2drop false                                     ( false )
;

: read   ( adr len -- #read )
[ifdef] fw-scan-set  fw-scan-set  [then]

   \ Poll the keyboard even if len is 0, as extra insurance against overrun
   get-scan                                   ( adr len )
   tuck                                       ( len adr len )
   begin                                      ( len adr' len' )
      dup 0<>  if  getkey  else  false  then  ( len adr' len' [ char ] flag )
   while                                      ( len adr' len' char )
      2 pick c!                               ( len adr' len' )
      1 /string                               ( len adr'' len'' )
   repeat                                     ( len adr' len' )
   nip -                                      ( #read )
   dup  0=  if  drop -2  then                 ( #read | -2 )
;

: ring-bell  ( -- )  " audio" " ring-bell" execute-device-method drop  ;

: selftest  ( -- fail? )
   kbd-refcount @ 0<>  if  
      0 exit
   then
   reset  keyboard-present?  if
      false
   else
      ." No keyboard found" cr  true
   then
;

[ifdef] apple-chords
0 value previous-scan		\ Memory for detecting key chords.
\ These words are for detecting key-chords
\ chord-index takes two scan codes, and returns and index which
\ tells if a pair of keys is held down. The scan codes are expected to
\ be regular keys. Other code will deal with the cntl, alt etc.

\ 1 = forth prompt on scc-a  o-f
\ 2 = menu           o-m
\ 3 = set NVRAM defaults n-v
\ 4 = set Diag-mode o-d
\ 5 = forth prompt on com1
\ add others as needed.   

create chord-pairs      \ table of pairs of scan codes to watch for
\ for scancodes
h# 18 h# 21 , ,         \ o f - debug out scca
h# 18 h# 32 , ,         \ o m - force firmware menu
h# 31 h# 2f , ,         \ n v - reset nvram
h# 18 h# 20 , ,         \ o d - set true to diagnostic-mode?
h# 18 h# 2e , ,         \ o c - debug out com1
create end-pairs

\ chord-index searches for special key pairs.
: chord-index ( n1 n2 -- index ) \ index where  (n1n2 or n2n1) found. 0=none.
   end-pairs chord-pairs do
      2dup  i 2@  d=  -rot       ( flag1 n1 n2 )
      2dup swap  i 2@  d=        ( flag1 n1 n2 flag2 )
      -rot 2swap                 ( n1 n2 flag1 flag2 )
      or  if                     ( n1 n2 ) \ if match found ....
         2drop                    (  )  \ drop n1 n2
         i chord-pairs -          ( relative addr where found )
         2 cells /  1+            ( index ) \  return index showing where match found
         unloop exit              \ leave now
      then
   2 cells +loop                ( n1 n2 ) \ step through 2 cells at a time
   2drop                         (  )  \ drop n1 n2
   false                        \ if we never exit no match was found.
;

\ set-specials  searches for ctrl-alt-x-y key combinations which do 
\ special things like force the menu or debug out the com port.
: set-specials ( scancode - flag )
   false swap 
   dup h# e0 = if  drop  exit  then
   dup h# 80 and  0=  swap  h# 7f and   ( false down? scan )
   dup h# 60 >=  if  2drop  exit  then
   case					( false  down? scan )
     1d  of  to ctrl?   endof    \ CTRL-L  (CTLR-R is eO 1d)
     38  of  to alt-gr? endof    \ ALT-L   (ALT-R is e0 38)
     nip alt-gr? ctrl? and if 		( false scan )
        ." ca " 
        dup previous-scan chord-index ?dup if ( false scan index )
            rot drop swap  		( index scan )
        then 
        dup to previous-scan
     then 
   endcase				( index )
;

\ get-key-chord  polls the keyboard for approx. 2 seconds looking for a 
\ special key code sequence.  
: get-key-chord ( -- chord-index)
   reset			\ reset-kbd
   unlock
   0 to previous-scan 
   \ Loop for approximately 2 seconds on a 200 Mhz 604. 
   8000 0 do
      get-scan deque? if
         set-specials ?dup if 
	    \ make sure to unlock the keyboard when finished. 
            unloop unlock exit 
         then 
      then
   loop

   \ Only get here if no keys were pressed so return false. 
   false
;
[then]


\ end0
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
