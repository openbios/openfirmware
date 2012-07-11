\ This file is preserved only for historical interest.
\ It's difficult to get SoC wakeups from the keypad controller,
\ so we configure the game key inputs as GPIOs instead.

fload ${BP}/cpu/arm/mmp2/keypad.fth

[ifdef] notdef  \ CForth turns on the keypad; resetting it makes it not work
stand-init: keypad
   keypad-on
   8 keypad-direct-mode
;
[then]

: keypad-bit  ( n keypad out-mask key-mask -- n' keypad )
   third invert  and  if    ( n keypad out-mask )
      rot or swap           ( n' keypad )
   else                     ( n keypad out-mask )
      drop                  ( n keypad )
   then                     ( n' keypad )
;

: gpio-rotate-button?  ( -- flag )  rotate-gpio# gpio-pin@ 0=  ;
' gpio-rotate-button? to rotate-button?

: keypad-game-key@  ( -- n )
   0                                        ( n )
   gpio-rotate-button?  if  button-rotate or  then   ( n )
   scan-keypad                              ( n keypad )
   button-o       h# 01  keypad-bit         ( n' keypad )
   button-check   h# 02  keypad-bit         ( n' keypad )
   button-x       h# 04  keypad-bit         ( n' keypad )
   button-square  h# 08  keypad-bit         ( n' keypad )
   rocker-up      h# 10  keypad-bit         ( n' keypad )
   rocker-right   h# 20  keypad-bit         ( n' keypad )
   rocker-down    h# 40  keypad-bit         ( n' keypad )
   rocker-left    h# 80  keypad-bit         ( n' keypad )
   drop                                     ( n )
;
' keypad-game-key@ to game-key@
