purpose: Standard last-phase startup sequence
copyright: Copyright 1997 Firmworks  All Rights Reserved

: restore-stdout  ( -- )
   " restore" stdout @ ['] $call-method  catch  if  3drop  then
;

defer secondary-diagnostics  ' noop to secondary-diagnostics

defer kbd-extras  \ for  fan, key-chord
' noop to kbd-extras

: startup  ( -- )
   standalone?  0=  if  exit  then

   copy-reboot-info

   \ Ensure a clean startup state regardless of the development
   \ environment's use of these variables
   0 stdin !  0 stdout !  0 to my-self

   " nvramrc" ?type
   use-nvramrc?  if  nvramrc safe-evaluate  then

   install-alarm

   auto-banner?  if
      " Probing" ?type  probe-all
      " Install console" ?type  install-console
      banner
   then

   hex
   warning on
   only forth also definitions

\   install-alarm

   #line off

   secondary-diagnostics

   kbd-extras
   auto-boot
   restore-stdout

   user-interface
;
