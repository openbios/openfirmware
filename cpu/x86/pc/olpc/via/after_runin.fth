\ Post-runin boot script $Revision$

\ The Linux-based runin selftests put this file at int:\runin\olpc.fth
\ after they have finished.  On the next reboot, OFW thus boots this
\ script instead of int:\boot\olpc.fth .  This script either displays
\ the failure log (if int:\runin\fail.log is present) or modifies the
\ manufacturing data tags to cause the next boot to enter final test.

[ifndef] $read-file
\ Read entire file into allocated memory
: $read-file  ( filename$ -- true | data$ false )
   open-dev  ?dup  0=  if  true exit  then  >r  ( r: ih )
   " size" r@ $call-method  drop   ( len r: ih )
   dup alloc-mem  swap             ( adr len r: ih )
   2dup " read" r@ $call-method    ( adr len actual r: ih )
   r> close-dev                    ( adr len actual )
   over <>  if                     ( adr len )
      free-mem  true exit
   then                            ( adr len )
   false
;
[then]

[ifndef] $(delete-tag)
: ($delete-tag)  ( adr len -- )
   2dup  ram-find-tag  0=  if  2drop exit  then  ( tagname$ ram-value$ )
   2nip                         ( ram-value$ )

   2dup + c@ h# 80 and          ( ram-value$ tag-style )
   if  4  else  5  then  +  >r  ( tag-adr tag-len )
   ram-last-mfg-data  >r        ( tag-adr r: len bot-adr ) 
   r@  2r@ +                    ( tag-adr src-adr dst-adr r: len bot-adr )    
   rot r@ -                     ( src-adr dst-adr copy-len r: len bot-adr ) 
   move                         ( r: len bot-adr )
   r> r> h# ff fill             ( )
;
[then]

h# 128 buffer: ms-value
h# 128 buffer: bd-value

: set-tags-for-fqa  ( -- )
   " NM" find-tag  if  ms-value place  then
   " NB" find-tag  if  bd-value place  then

   get-mfg-data

   " TS" ($delete-tag)
   " MS" ($delete-tag)
   " BD" ($delete-tag)
   " NM" ($delete-tag)
   " NB" ($delete-tag)

   ms-value count " MS" ($add-tag)
   bd-value count " BD" ($add-tag)
   " FINAL"       " TS" ($add-tag)

   put-mfg-data
;

: fail-log-file$  ( -- name$ )  " int:\runin\fail.log"   ;

: after-runin  ( -- )
   fail-log-file$ $read-file  0=  if  ( adr len )
      page
      show-fail
      ." Type a key to see the failure log"
      key drop  cr cr
      list
   else
      set-tags-for-fqa
      " int:\runin\olpc.fth" $delete-all

      page
      show-pass
      ." System is ready for final test" cr
   then

   ." Type a key to power off"
   key cr
   power-off
;

after-runin
