\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fwritstr.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)fwritstr.fth 3.15 04/03/30
purpose: ANSI X3.64 terminal emulator (escape sequence parser)
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ ANSI 3.64 Terminal Emulator.
decimal
headerless
\ ansi-emit is the routine which handles the current character.
\ It is deferred because the terminal emulator can be in one of several
\ states, depending on the previous characters.  For each distinct state,
\ a different routine is installed as the action performed by ansi-emit.
\ The states are:
\
\   alpha-state		This is the "normal" state.  Printable characters
\			are displayed, control characters are interpreted,
\			and the ESCAPE character switches to escape-state .
\
\   escape-state 	In this state, an ESCAPE has been seen and we
\			are expecting a "[" character to switch us to
\			escbrkt-state.  In escape-state, a few control
\			characters are recognized, and apart from that,
\			any non-"[" character switches to alpha-state .
\
\   escbrkt-state	An ESCAPE [  pair has been seen.  We collect numeric
\			arguments until an alphabetic command character
\			is received, then we execute the command and switch
\			to alpha-state .  Command characters are those
\			with ASCII codes numerically greater than or equal
\			to the ASCII code for the "@" character.
\
\   skipping-state	Entered from escbrkt-state if an invalid character
\			is received while waiting for a command character.
\			In skipping state, all non-command characters are
\			ignored, and the next command character switches
\			to alpha-state .

: ring-bell  ( -- )
   " ring-bell" stdin @  ['] $call-method catch  if
      3drop blink-screen
   then
;

\ set-line is also used by fb1-draw-logo
\ which is defined outside the termemu package
also forth definitions
: set-line  ( line -- )
   0 max  #lines    1- min  is line#    \ ['] line#    >body >user !
;
previous definitions

: set-column  ( column# -- )
   0 max  #columns  1- min  is column#  \ ['] column#  >body >user !
;
: +column  ( delta-columns -- )  column# +   set-column  ;
: +line  ( delta-lines -- )  line# +  set-line  ;

: /string  ( adr len n -- adr+n len-n )  over min  rot over + -rot -  ;

\ #newlines counts the number of newlines up to the end of the
\ string to be printed, or up to the next escape or form feed.
\ This is used to "batch" scrolls.
: #newlines  ( adr len -- adr len #newlines )
   2dup 1 -rot                          ( adr len 1 adr len )
   1 /string   bounds  ?do              ( adr len #newlines-so-far )
      i c@  bl <  if                    ( adr len #newlines-so-far )
         i c@  case
	    control J  of 1+     endof  \ Count linefeeds
	    control [  of leave  endof  \ Bail out on escapes
	    control L  of leave  endof  \ Bail out on formfeeds
         endcase
      then
   loop   ( adr len #newlines )
;

: kill-1line  ( -- )  #columns column# -  delete-characters  ;

: kill-line  ( -- )
   column#
   arginit  case
      1  of		\ Erase from beginning of line to cursor
         0 set-column  dup delete-characters dup insert-characters
      endof
      2  of		\ Erase entire line
         0 set-column  #columns delete-characters
      endof
      ( default, and 0 case )  kill-1line   \ Erase from cursor to end of line
   endcase
   set-column
;

: do-newline  ( adr len -- adr len )
   line#  #lines 1-  <  if

      \ We're not at the bottom of the screen, so we don't need to scroll
      line# 1+ set-line  ( adr len )

      \ Clear next line unless we're in wrap mode
      #scroll-lines 0=  if   kill-1line   then

   else  \ We're at the bottom of the screen, so we have to scroll

      \ In wrap mode, we just go to the top of the screen
      #scroll-lines 0=  if  0 set-line  kill-1line  exit  then

      \ In single-line scroll mode, we try to optimize out multiple scrolls
\        #scroll-lines  1 =  if               ( adr len )
\           #newlines                         ( adr len #newlines )
\        else
\           #scroll-lines                     ( adr len #scroll-lines )
\        then

      #scroll-lines                        ( adr len #scroll-lines )

      #lines min                           ( adr len #lines-to-scroll )
      line#                                ( adr len #lines line# )
      0 set-line   swap dup delete-lines   ( adr len line# #lines-to-scroll )
      - 1+  set-line                       ( adr len )
   then
;

\ Moves the cursor to the position indicated by arg0 and arg1
: move-cursor  ( -- )
   next-arg 0=  if  0  else  1 arg 1-  then  0 arg 1-
   set-line set-column
;
: kill-screen  ( -- )
   line# column#       ( line# column# )
   arginit case
      1 of		\ Erase from beginning of screen to cursor
         0 set-column  dup delete-characters  dup insert-characters
         0 set-line    over delete-lines  over insert-lines
         dup
      endof

      2 of		\ Erase entire screen
         0 set-line  0 set-column
         #lines delete-lines
      endof

      ( default, also explicitly the "0" case )
      kill-1line	\ Erase from cursor to end of screen
      1 +line  #lines  line# -  delete-lines
   endcase
   set-column set-line
;
: form-feed  ( -- )  0 set-line 0 set-column  erase-screen  ;

headers
true config-flag ansi-terminal?
headerless

\   alpha-state		This is the "normal" state.  Printable characters
\			are displayed, control characters are interpreted,
\			and the ESCAPE character switches to escape-state .
\
: alpha-emit  ( adr len char -- adr len )
[ifdef] nt-support
\ In order to support NT's screen-oriented installation stuff, we have
\ to suppress scrolling when the last line of the screen is exactly filled,
\ but no additional characters are output.
   pending-newline?  if
      false to pending-newline?  0 set-column  >r do-newline r>
   then
   draw-character
   column# #columns 1- u<  if  1 +column  else  true to pending-newline?  then
[else]
\ However, the above behavior doesn't work right with vi.
   draw-character
   column# #columns 1- u<  if  1 +column  else  0 set-column   do-newline then
[then]
;

: alpha-state  ( adr len char -- adr len )
   dup h# 7f and bl >=  if		\ Printable character
      alpha-emit  ( adr len )
   else					\ Control character
      false to pending-newline?
      case
         control G of  ring-bell                                endof
         control H of  -1 +column                               endof
         control I of  column# -8 and 8 +  set-column           endof
         control J of  ( adr len )  do-newline  ( adr len )     endof
         control M of  0 set-column                             endof
         control [ of  ansi-terminal?  if
			  ['] escape-state is ansi-emit
		       else
			  ascii ^ alpha-emit  ascii [ alpha-emit
		       then					endof
         h# 9b     of  ansi-terminal?  if
			  ascii [ escape-state
		       else
			  ascii ^ alpha-emit  ascii [ alpha-emit
		       then					endof
         \ ARC wants FF (^L) to be handled like linefeed
         control L of  form-feed                                endof
         \ ARC wants VT (^K) to be handled like linefeed
         control K of  -1 +line                                 endof
      endcase
   then
;
: enter-alpha-state  ( -- )  ['] alpha-state is ansi-emit  ;
: reset-modes  ( -- )
   1 is #scroll-lines
   enter-alpha-state
;
headers
also forth definitions
\ XXX we should probably do this with an escape sequence. Does ANSI define one?
: hide-text-cursor  ( -- )  false to showing-cursor?  toggle-cursor  ;
: reveal-text-cursor  ( -- )  true to showing-cursor?  toggle-cursor  ;
: reset-emulator  ( -- )  0 set-line  reset-modes  ;
previous definitions

headerless

\ Boldness applies retroactively only to the foreground color; the
\ current background color is unaffected.  However, setting the
\ background color applies the current boldness state of the foreground
\ color to the background color.  This gives a client program complete
\ and independent control over the boldness of both the foreground and
\ background colors (by judiciously sequencing the setting of colors
\ and boldness), and preserves as much as practical the semi-IBM-PC
\ semantics that ARC clients assume.  The semantics are not exactly the
\ same as the PC, because the PC (actually ANSI.SYS) zaps the colors
\ to dim white on black in response to CSI 0 m, and to black on dim
\ white in response to CSI 7 m, while some ARC clients (in particular
\ ARCINST.EXE) assume that CSI 0 m preserves the fundamental color scheme
\ that is currently in effect.  Convoluted?  You bet!
\
\ The fact that this implementation of CSI 7 m and CSI 0 m do not force
\ the colors back to black and white is also advantageous for programs
\ that use these sequences for "standout-start ... standout-end", for
\ which it is nice not to wantonly change the current color scheme.  It
\ is also important that CSI 0 m does not immediately alter the boldness
\ of the background color, because in the common case of a bright white
\ background, that prevents CSI 7 m ... CSI 0 m from changing the background
\ to dim white.

: bold  ( -- mask )  foreground-color 8 and  ;
: bold-on  ( -- )
   foreground-color 8 or  to foreground-color
;
: bold-off  ( -- )
   foreground-color 8 invert and  to foreground-color
;
: default-attributes  ( -- )  false to inverse?  bold-off  ;
: >color#  ( ansi-color-code -- palette# )
   10 mod  " "(00 04 02 06 01 05 03 07)" drop + c@
;
: do-color  ( param -- )
   case
       0  of  default-attributes   endof
       1  of  bold-on              endof
       2  of  bold-off             endof
       7  of  true  to inverse?    endof
   d# 27  of  false to inverse?    endof
   ( default )
      dup d# 30 d# 37 between  if
         dup >color#  bold or  to foreground-color
      else
         dup d# 40 d# 47 between  if
            dup >color# to background-color	\ Only embolden foreground.
         then
      then
   endcase
;
0 value no-args?
: set-colors  ( -- )
   16-color?  if
      next-arg 1+  0  do  i arg do-color  loop
   else
      inverse-screen?  arginit 0<>  xor  is inverse?
   then
;
: handle-modes  ( flag -- )
   next-arg 1+  0  do
      i arg  case
\ This doesn't work because turning off the escape sequence parser prevents
\ parsing the sequence to return to ANSI mode.
\        d#  3 of  dup to ansi-terminal?   endof
         d# 25 of  dup to showing-cursor?  endof
      endcase
   loop
   drop
;
: set-ansi-modes    ( -- )  true  handle-modes  ;
: reset-ansi-modes  ( -- )  false handle-modes  ;
: skipping-state  ( char -- )
   ascii @  >=  if  enter-alpha-state  then
;
: arg0  ( -- n )  0 arg  ?dup  0=  if  1  then  ;
: do-command  ( char -- )
   enter-alpha-state
   0 arg  to arginit
   case
      ascii @  of  arg0 insert-characters  endof
      ascii A  of  arg0 negate  +line      endof
      ascii B  of  arg0         +line      endof
      ascii C  of  arg0         +column    endof
      ascii D  of  arg0 negate  +column    endof
      ascii E  of  line# arg0 +  set-line  endof
      ascii f  of  move-cursor  endof
      ascii h  of  set-ansi-modes     endof
      ascii l  of  reset-ansi-modes   endof
      ascii H  of  move-cursor  endof
      ascii J  of  kill-screen  endof
      ascii K  of  kill-line    endof
      ascii L  of  arg0 insert-lines    endof
      ascii M  of  arg0 delete-lines    endof
      ascii P  of  arg0 delete-characters    endof
      ascii m  of  set-colors  endof
      ascii p  of  inverse-screen?  if
                      invert-screen
                      inverse? 0= is inverse?
                      false is inverse-screen?
		   then  endof
      ascii q  of  inverse-screen? 0=  if
	              invert-screen
                      inverse? 0= is inverse?
                      true is inverse-screen?
		   then  endof
      ascii r  of  arginit is #scroll-lines  endof
      ascii s  of  reset-modes  reset-screen  endof
         ( default )  dup ascii @  <  if  ['] skipping-state is ansi-emit  then
   endcase
;
: escbrkt-state  ( char -- )
   dup  ascii 0  ascii 9  between  if	\ Collect number
      next-arg arg  10 *  ascii 0  -  +  next-arg to arg
   else  dup  ascii ;  =  if		\ Shift arguments
      drop
      next-arg 1+ to next-arg
      0 next-arg  to arg
   else
      do-command
   then then
;
: (escape-state  ( char -- )
   0 to next-arg
   0 0  to arg
   case
      ascii [    of  ['] escbrkt-state is ansi-emit    endof
      control L  of  enter-alpha-state  form-feed      endof
      control J  of  endof
      control M  of  endof
      control [  of  endof
      control ?  of  endof
      ( default )    enter-alpha-state
   endcase
;
\ Fix the forward reference
' (escape-state is escape-state

also forth definitions
headers
: ansi-type  ( adr len -- )
\ XXX here we should test for terminal locked, and if it is already
\ locked, we are being re-entered, so we save the current state
\ and switch to alpha state.
   terminal-locked? on
   showing-cursor?  if  toggle-cursor  then         ( adr len )
   \ We save the string extent in variables so #newlines can
   \ find the current position.
   begin  dup  while       ( adr len )
      over c@  ansi-emit   ( adr len )
      1 /string            ( adr' len' )
   repeat                  ( adr 0 )
   2drop                   ( )
   showing-cursor?  if  toggle-cursor  then
\ XXX Here we should restore the previous state if necessary.
   terminal-locked? off
;

: install-terminal-emulator  ( -- )
   \ Set the terminal emulator's frame-buffer-adr
   \ to be the same as the device that opened it
   \ in the first place.
   frame-buffer-adr my-termemu package( is frame-buffer-adr )package
[ifdef] reboot-saves-cursor
   reboot?  if
      \ Restore the cursor to the position that was saved before the reset
      get-reboot-info          ( bootpath,len line# column# )
      #columns min  is column# ( bootpath,len line# )
      #lines  min  is line#    ( bootpath,len )
      2drop                    (  )
      line# column# or 0= if  erase-screen  then
   else
      erase-screen
   then
[else]
   erase-screen
[then]

   reset-screen     \ Enables video
   #lines termemu-#lines !
   toggle-cursor
;
\ Don't use this for now; we need to fix the escape sequence parser so that
\ it will look for the "ansi-terminal" sequence even when in "dumb-terminal"
\ mode.
\ : dumb-terminal  ( -- )  " "(9b)25h" type  ;
\ : ansi-terminal  ( -- )  " "(9b)25l" type  ;
previous definitions

headers
: open ( -- success? )
   my-self is my-termemu
   ['] romfont is font
   reset-emulator
   true
;
: close ( -- )  ;
