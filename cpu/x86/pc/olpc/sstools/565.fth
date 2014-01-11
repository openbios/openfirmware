\ dump frame buffer in C565 format

dev /display
: fb-va  ( -- fb )  frame-buffer-adr  ;
dend

: ts$  ( -- adr len )
   time&date >unix-seconds push-decimal 0 <# #s #> pop-base
;

: putw  ( w -- )  wbsplit  swap  ofd @ fputc  ofd @ fputc  ;

: fb-save  ( file ( -- )
   writing
   " C565" ofd @ fputs
   screen-wh swap putw putw
   " fb-va" screen-ih $call-method
   screen-wh swap drop 0  do            ( fb )
      screen-wh drop 0  do              ( fb )
         dup w@                         ( fb rgb565 )
         putw
         wa1+                           ( fb' )
      loop                              ( fb' )
   loop drop                            ( )
;

: fb  ( -- )
   ts$
   " u:\"
   " fb-save %s%s.565" sprintf
   screen-ih remove-output
   2dup type cr
   ['] evaluate catch ?dup if nip nip .error then
   screen-ih add-output
;

dev /keyboard
: handler?  ( scan-code -- flag )
   dup h# 73 ( × ) =  if  fb true  exit  then
   handle-volume?
;
\ FIXME: during check-alarm, the data stack pointer is in another
\ place, leading to large negative depth and ?enough failures, in
\ particular in writing.
\ ' handler? to scan-handled?
dend

