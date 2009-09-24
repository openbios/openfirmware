
d# 4096 constant max-data
d# 4356 constant my-max-buf
d# 0 constant my-max-raw
d# 1 constant my-max-mpx

\ my-max-buf instance buffer: session-buf  \ 4096 + 4 (session header length)
0 instance value session-buf
0 instance value x-adr

: start-encode  ( -- )  session-buf to x-adr  ;
: +xb  ( byte -- )  x-adr c!  x-adr 1+ to x-adr  ;
: +xw  ( word -- )  x-adr le-w!  x-adr wa1+ to x-adr  ;
: +xl  ( long -- )  x-adr le-l!  x-adr la1+ to x-adr  ;
: +xbytes  ( adr len -- )
   tuck x-adr swap move   ( len )
   x-adr + to x-adr       ( )
;
: +xalign  ( -- )  x-adr session-buf - 1 and  if  0 +xb  then  ;

: +nibble  ( b -- )  [char] A + +xb  ;
: bnsplit  ( b -- lo hi )
   dup h# f and  swap 4 rshift h# f and
;
: +split   ( b -- )  bnsplit  +nibble +nibble  ;

\ String is e.g. "BDCO"(00)" or "*SMBSERVER "
\ The last character is usually either 00 or space
: split-last  ( adr len -- lastchar adr len' )
   2dup + 1- c@  -rot  1-   ( lastchar adr len' )
;
: +l1  ( adr len -- )
   split-last               ( lastchar adr len'  )
   d# 15 min   tuck         ( lastchar len' adr len' )
   bounds  ?do              ( lastchar len )
      i c@ +split           ( lastchar len lo hi )
   loop                     ( lastchar len )
   d# 15  swap  ?do         ( lastchar )
      bl +split             ( lastchar )
   loop                     ( lastchar )
   +split                   ( )
;
: .one  ( char -- )
   push-hex
   dup h# 20 h# 7f between  if
      emit
   else
      bnsplit  ." (" .2 .2  ." )"
   then
   pop-base
;
: -nulls  ( adr len -- adr len' )
   begin  dup  while     ( adr len )
      2dup + 1-  c@  if  ( adr len )
         exit
      then               ( adr len )
      1-                 ( adr len' )
   repeat                ( adr len )
;
: .l1  ( adr len -- )
   split-last          ( lastchar adr len' )
   -trailing  -nulls   ( lastchar adr len' )
   bounds  ?do
      i c@  .one
   loop
;
: +wildcard  ( adr len -- )
   d# 16 min   tuck         ( len' adr len' )
   bounds  ?do              ( len )
      i c@ +split           ( len )
   loop                     ( len )
   d# 16  swap  ?do         ( )
      0 +split              ( )
   loop                     ( )
;

: +l2  ( adr len -- )  \ Encode foo.bar.oof
   [char] .  left-parse-string      ( rem$ head$ )
   d# 32 +xb  +l1                   ( rem$ )
   begin  dup  while                ( rem$ )
      [char] .  left-parse-string   ( rem$ head$ )
      d# 63 max  dup +xb            ( rem$ head$ )
      bounds  do  i c@ +xb  loop    ( rem$ )
   repeat                           ( rem$ )
   2drop                            ( )
;
: l2-split  ( $ --  rem$ this$ )  \ $ must be non-empty
   over 1+  over c@        ( adr len  thisadr thislen )
   dup h# c0 and  abort" L2 name contains label string pointer (unimplemented)"
   2swap  third            ( thisadr thislen  adr len thislen )
   1+ /string              ( thisadr thislen  remadr remlen )
   2swap                   ( rem$ this$ )
;

: .l2  ( adr len -- )
   l2-split .l1                     ( rem$ )
   begin  dup  while                ( rem$ )
      l2-split                      ( rem$ this$ )
      dup  if  ." ."  then          ( rem$ this$ )
      bounds  ?do  i c@ emit  loop  ( rem$ )
   repeat                           ( rem$ )
   2drop                            ( )
;


\ Name service implementation would go here...


: session{  ( type -- )
   start-encode   ( type )
   +xb            \ type
   0 +xb          \ flags
   0 +xb  0 +xb   \ length - patched later
;

: }session  ( -- error? )
   x-adr  session-buf -  4 -  ( length )
   lwsplit               ( lo hi )
   dup 1 >  abort" Session length too long"
   session-buf 1+ c!       ( lo )
   session-buf 2+ be-w!  ( )
   session-buf x-adr over -  tuck  " write" $call-parent  ( len actual )
   dup -1 =  if     ( len actual )
      ." TCP connection dropped" cr
      2drop true  exit
   then             ( len actual )
   <>  dup  if  ." TCP short write" cr  then
;

\ XXX we should probably have a timeout
: get-tcp  ( adr len -- error? )
   begin  dup  while       ( adr remlen )
      2dup " read" $call-parent   ( adr remlen thislen )
      dup -1 =  if                ( adr remlen thislen )
         3drop true exit
      then                        ( adr remlen thislen )
      \ -2 means "none available yet"
      dup -2 =  if  drop 0  then  ( adr remlen thislen )
      /string                     ( adr remlen' )
   repeat                         ( adr remlen' )
   2drop  false
;

: +session-label  ( $ -- )  bl +xb  +l1  0 +xb  ;

0 instance value /session-response
: .session-error  ( code -- )
   ." Session error: "
   case
      h# 80 of  ." Not listening on called name"  cr  endof
      h# 81 of  ." Not listening for calling name"  cr  endof
      h# 82 of  ." Called name not present"  cr  endof
      h# 83 of  ." Insufficient resources"  cr  endof
      h# 8f of  ." Unspecified error"  cr  endof
      ( default )  ." Undefined error code: " dup .x  cr
   endcase
;

: do-retarget  ( -- error? )
   /session-response 6 <>  if
      ." Incorrect length for session retarget response" cr
      true exit
   then

   ." Retarget to IP "  session-buf .ipaddr
   ." port " session-buf 4 + be-w@ .d  cr
   true
;

: get-session-response  ( -- true | adr len false )
   session-buf 4 get-tcp  if  true exit  then     ( )
   session-buf c@          ( type )
   session-buf 2+ be-w@    ( type length-lo )
   session-buf 1+ c@ 1 and ( type length-lo length-hi )
   wljoin to /session-response  ( type )
   
   session-buf /session-response  get-tcp  if  true exit  then   ( type )

   case                    ( )
      0      of      \ Session message
         session-buf /session-response  false exit
      endof

      h# 82  of      \ Positive response
         session-buf /session-response  false exit
      endof

      h# 83  of      \ Negative response
         /session-response 1 <>  if
            ." Incorrect length for negative session response" cr
            true exit
         then
         session-buf c@ .session-error
         true exit
      endof

      h# 84  of  do-retarget  endof

      ( default )
      ." Undefined session response code: " .x cr
      true exit
   endcase         
;

: start-session  ( calling$ called$ -- error? )
   h# 81 session{   ( calling$ called$ )
   +session-label   ( calling$ )
   +session-label   ( )
   }session  if  true exit  then   ( )
   get-session-response  if        ( )
      true                         ( true )
   else                            ( adr len )
      2drop false                  ( false )
   then                            ( error? )
;
