\ See license at end of file
purpose: Automatic inflation of deflated dropin drivers

headerless
defer flip-code?  ' false is flip-code?
0 0 2value inflater
0 0 2value inflate-ws

defer get-inflater
: (get-inflater)  ( -- )
   " inflate" find-drop-in  0= abort" Can't find inflater"   ( adr len )
   to inflater                                     ( di-adr )
   flip-code?  if  inflater lbflips  then          ( )
   inflater sync-cache                             ( )
\   close-drop-in
   h# 10000 dup alloc-mem swap to inflate-ws       ( adr exp-adr )
;
' (get-inflater) to get-inflater

defer release-inflater
: (release-inflater)  ( -- )
   inflate-ws free-mem                             ( exp-len )
   inflater free-mem
;
' (release-inflater) to release-inflater

\ The "nohdr" flag is 0 if the image has a header, nonzero if no header
: (inflate)  ( adr expanded-adr nohdr? -- expanded-len )
   inflate-ws  2dup erase    drop                  ( adr exp-adr nohdr? ws )
   inflater drop  inflate-ws +  sp-call            ( exp-adr adr nohdr ws exp-len )
   nip nip nip nip                                 ( exp-len )
;

: inflate  ( adr expanded-adr -- expanded-len )
   get-inflater
   false (inflate)
   release-inflater
   dup -2 =  abort" Inflate size error"
   dup -1 =  abort" Inflate CRC error"
;

: try-inflate  ( id -- adr len )
   read-dropin                                     ( adr len )
   di-expansion be-l@  ?dup  if                    ( adr len len' )
      -rot 2>r                                     ( len' )  ( r: adr len )
      dup  alloc-mem                               ( len' adr' )
      2r@ drop over  inflate  drop                 ( len' adr' )
      swap                                         ( adr' len' )
      2r> free-mem                                 ( adr' len' )
   then
;
' try-inflate to ?inflate

: (?inflate-loaded)  ( -- )
   load-base  " "(1f8b08)"  comp 0=  if
      load-base  loaded +  tuck  inflate  !load-size  ( infl-adr )
      loaded move                                     ( )
   then
;
' (?inflate-loaded) to ?inflate-loaded
headers
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
