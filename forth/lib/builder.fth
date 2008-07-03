\ See license at end of file
purpose: Firmware build management system

\needs files"        fload ${BP}/forth/lib/stringop.fth
\needs today         fload ${BP}/forth/lib/date.fth
\needs add-dropin    fload ${BP}/forth/lib/mkdropin.fth
\needs set-extension fload ${BP}/forth/lib/basename.fth
\needs stack:        fload ${BP}/forth/lib/stack.fth
\needs $stack:       fload ${BP}/forth/lib/strngstk.fth

false value build-clean?
false value show-intermediates?
false value show-sources?
true  value show-rebuilds?
false value tagging?
: clean    ( -- )  true to build-clean?  ;
: verbose  ( -- )  true to show-intermediates?  ;
: prolix   ( -- )  true to show-sources?  verbose  ;
: quiet    ( -- )  false to show-rebuilds?  ;

false value show-dirs?

warning @ warning off
: $chdir?  ( adr len -- error )
   dup  0=  if  2drop  " ."   then
   show-dirs?  if  ." --- Dir: "  2dup type cr  then
   $cstr  d# 96 syscall  drop  retval
;
warning !

: make-directory  ( adr len -- error? )
   \ Many implementations of "mkdir()" do not like trailing delimiters
   dup  if
      2dup + 1- c@  dup [char] / =  swap [char] \ =  or  if  1-  then
   then

   $cstr  d# 192 syscall  drop retval
;
: lastchar   ( adr len -- char )   2dup + 1- c@  ;
: $build?   ( adr len -- builddir )
   lastchar dup ascii / = swap ascii \ = or if  1-  then	( adr len' )
   basename  " build"  $=
;
: $chdir!  ( adr len -- )
   2dup  $chdir?  0= if	 2drop exit  then	( adr len )
   2dup $build? if				( adr len )
      2dup make-directory  if			( adr len )
	 ." Can't make directory " type cr  error-exit
      then					( adr len )
      2dup  $chdir?  0=  if  2drop exit  then
   then
   ." Can't change directory to " type cr  error-exit
;

: cwd$  ( -- adr len )  d# 200 syscall  retval cscount  ;

$stack: dirstack	\ Stack of pointers to previous directory names

: $pushd  ( adr len -- )
   cwd$ dirstack $push        ( adr len )  \ Stack old directory name
   $chdir!				   \ Go to new directory
;
: popd  ( -- )
   \ Return to previous directory
   dirstack $top $chdir? abort" Can't return to previous directory"
   dirstack $drop         \ Pop the stack 
;

0 0 2value bp$
: set-bp$  ( -- )
   " ${BP}" $pushd cwd$ ( adr len )
   dup alloc-mem $save  ( adr' len' )
   to bp$               ( )
   popd
;

: -bp ( adr len -- adr' len' )  \ take expanded "${BP}/" prefix out of path
   bp$ 2over substring?  if      ( adr len )
      bp$ nip 1+ /string         ( adr' len' )
   then
;

: $sh  ( adr len -- )
   show-rebuilds?  if  ." --- Cmd: " 2dup type cr  then
   $cstr d# 88 syscall  drop retval  if  error-exit  then
;

false value show-times?
: modtime  ( adr len -- n )
   2dup $cstr  d# 176 syscall  drop  retval
   show-times?  if
      dup push-hex 8 u.r pop-base  space -rot type cr
   else
      -rot 2drop
   then
;

: skip-line  ( -- )  postpone \  ;

: parse-filename  ( "name" -- adr len )  safe-parse-word  ;

: parse-timestamp  ( "hex-number" -- u )  parse-word $number  ;

\ The timestamp of the current target.
d# 40 /n* stack: target-time

\ The name of the target whose dependencies we are checking
$stack: target-names

\ The command line that was used to build the target.
$stack: command-lines

\ The name of the file that was after "dictionary:"
$stack: dictionary-files

\ The name of the current build file
$stack: build-files

d# 40 /n* stack: rebuild

: $replace  ( adr len $stack -- )  dup $drop  $push  ;

: top!  ( value stack -- )  dup pop drop  push  ;

: set-rebuild  ( -- )  true rebuild top!  ;

vocabulary extensions
defer source-file
defer intermediate-file

: check-date  ( adr len -- )
   \ There's no point in checking additional source files once we
   \ know that we must rebuild.
   rebuild top@  if  2drop exit  then

   show-sources?  if  ." source-file: " 2dup type cr  then

   2dup modtime  ?dup if                   ( name$ u )
      target-time top@ u>  if              ( name$ )

         \ If the target file doesn't exist, the message is misleading
         target-time top@ 0<>  show-rebuilds?  and  if
            ." --- "
            type  ."  is newer than the target file " target-names $top type cr
         else
            2drop
         then

\         out-of-date

         \ We can't just perform the rebuild right away, because there may
         \ be intermediate files that need to be rebuilt first, so we just
         \ set a flag that says we need to rebuild when all the checking is
         \ complete.
         set-rebuild
      else
         2drop
      then
   else                                    ( name$ )
      type ."  is missing" cr
      abort
   then
;

: handle-input  ( adr len -- )
   2dup basename  ['] extensions search-wordlist  if  execute exit  then
   2dup extension ['] extensions search-wordlist  if  execute exit  then
   source-file
;

: $get-macro  ( macro$ -- expansion$ )
   2dup  ['] macros $vfind  if
      nip nip  execute
   else
      ." No expansion for macro: " type cr  abort
   then
;

h# 256 buffer: s1
h# 256 buffer: s2
0 0 2value the-string
: other-string  ( -- )
   the-string drop s1 =  if  s2  else  s1  then  0 to the-string
;
: $append  ( str -- )
   tuck  the-string + swap move  the-string rot + to the-string
;
: 2-rot  ( $1 $2 $3 -- $3 $1 $2 )  2swap 2>r 2swap 2r>  ;
: another-macro?  ( str -- str false  |  tail$ macro$ head$ flag )
   [char] & split-string                  ( head$ tail$ )
   \ The shortest possible macro has 1 characters, e.g. &X
   dup 1 <  if  nip + false exit  then    ( head$ rem$ )
   1 /string                              ( head$ rem$ ) \ Remove the '&'
   bl split-string                        ( head$ macro$ rem$''' )
   2-rot  2swap                           ( tail$ macro$ head$ )
   true
;
0 value expanded?
: expand1?  ( $1 -- $2 expanded? )
   false to expanded?
   other-string                   ( $1 )
   begin  another-macro?  while   ( tail$ macro$ head$ )
      $append                     ( tail$ macro$ )
      $get-macro $append          ( tail$ )
      true to expanded?           ( tail$ )
   repeat                         ( tail$ )
   $append                        ( )
   the-string expanded?           ( $2 expanded? )
;
: expand-macros  ( $1 -- $2 )  begin  expand1?  0= until  ;

also macros definitions
: this  ( -- $ )  build-files $top  ;
: dictionary  ( -- $ )  dictionary-files $top  ;
: sv9fth    ( -- $ )  " ${HOSTDIR}/sv9fth"  ;
: sparcfth  ( -- $ )  " ${HOSTDIR}/sparcfth"  ;
: alphafth  ( -- $ )  " ${HOSTDIR}/alphafth"  ;
: mipsfth   ( -- $ )  " ${HOSTDIR}/mipsfth"   ;
: ppcforth  ( -- $ )  " ${HOSTDIR}/ppcforth"  ;
: x86forth  ( -- $ )  " ${HOSTDIR}/x86forth"  ;
: 68kforth  ( -- $ )  " ${HOSTDIR}/68kforth"  ;
: armforth  ( -- $ )  " ${HOSTDIR}/armforth"  ;
: cforth    ( -- $ )  " ${HOSTDIR}/cforth"  ;
: builder   ( -- $ )  " ${HOSTDIR}/forth ${HOSTDIR}/../build/builder.dic"  ;
: tokenize  ( -- $ )  " ${HOSTDIR}/forth ${HOSTDIR}/../build/builder.dic"  ;
: output  ( -- $ )  target-names $top  ;
previous definitions

0 value nest-depth
: run-file  ( filename$ -- )
   2dup build-files $replace
   show-intermediates?  if  ."  (" 2dup type ." )" cr  then
   included
;
vocabulary intermediates

vocabulary tags
: this-file?  ( name$ prefix$ suffix$ -- name$ false | name$' true )
   2>r 2over 2swap 2r>               ( name$ prefix$ suffix$ )
   $enclose                          ( name$ name$' )
   2dup $file-exists?  if            ( filename$ filename$' )
      2nip true                      ( filename$' true )
   else                              ( filename$ filename$' )
      2drop false                    ( filename$ false )
   then
;

: find-log-file?  ( filename$ -- filename$ false | filename$' true )
   build-clean? if
      2dup    " "    " .log"  this-file? if
	 2dup delete-file drop
      then
      2drop
   then
   " "    " .log"  this-file?
;

: find-bld-file?  ( filename$ -- filename$ false | filename$' true )
   " "          " .bth"  this-file?  if  true exit  then    ( filename$ )
   " ../"       " .bth"  this-file?  if  true exit  then    ( filename$ )
   " ../../"    " .bth"  this-file?  if  true exit  then    ( filename$ )
   " ../../../" " .bth"  this-file?  if  true exit  then    ( filename$ )
   false
;

\ What to do when a ".bth" file is encountered
defer handle-bld-file  ( name$ -- )
' run-file to handle-bld-file

\ What to do when a ".log" file is encountered
defer handle-log-file  ( name$ -- )
' run-file to handle-log-file

: push-build-state  ( target-name$ -- .. old-order )
   target-names $push
   " " command-lines $push
   " " build-files  $push
   " " dictionary-files $push
   0 target-time push
   false rebuild push
   get-order  ['] tags 1 set-order
   nest-depth 1+ to nest-depth
   d# 123454321
;
: pop-build-state  ( .. old-order -- )
   dup d# 123454321 <>  if  ." Stack depth changed"  cr  else drop  then
   nest-depth 1- to nest-depth
   set-order
   rebuild top@  if
      show-rebuilds?  if
         ." --- Rebuilding " target-names $top type cr
      then
      command-lines $top expand-macros $sh
   then
   rebuild pop drop
   dictionary-files $drop
   build-files $drop
   command-lines $drop
   target-names $drop
   target-time pop drop
;

\ What to do when neither a ".bth" nor a ".log" file is found
defer no-bld-file  ( name$ -- )
: (no-bld-file)  ( filename$ -- )
   tagging? if   \ convert absolute to relative pathname by cutting of "$BP/"
      ??cr
      cwd$ -bp type
      ." /" type cr
   else
      2dup $file-exists?  if
         2drop				\ don't complain
      else
         ." Target file " type ."  does not exist, and there is" cr
         ." no .log or .bth file for it." cr abort
      then
   then
;
' (no-bld-file) to no-bld-file

: handle-log-or-bld  ( -- )
   target-names $top find-log-file?  if  modtime  else  2drop 0  then  ( l b )
   target-names $top find-bld-file?  if  modtime  else  2drop 0  then  ( l b)
   2dup  or  if                                                  ( ltime btime)
      \ At least one of the .log or .bld files exists, so use the newer
      target-names $top 2swap  u<=  if                           ( name$ )
         find-bld-file?  drop handle-bld-file                    ( )
      else                                                       ( name$ )
         find-log-file?  drop handle-log-file                    ( )
      then                                                       ( )
   else                                                          ( 0 0 )
      \ There is neither a .log file nor a .bld file
      2drop  target-names $top no-bld-file                       ( )
   then
;

: $handle-file  ( filename$ -- )
   show-intermediates?  if  nest-depth spaces ." (( " 2dup type  then

   2dup dirname $pushd				( filename$ )
   basename 

   \ Skip the dependency check if a "<target>.ok" file exists
   2dup  " "       " .ok"  $enclose $file-exists?  if
      2drop  popd  exit
   then

   push-build-state                          ( old-order .. )
   handle-log-or-bld                         ( old-order .. )
   pop-build-state                           ( )
   popd
   show-intermediates?  if  nest-depth spaces ." ))" cr  then
;

: hash-name  ( name$ -- name$' )  dup d# 31 -  0 max  /string  ;

defer intermediate-action  ( name$ -- )
: build-intermediate  ( name$ -- )
   2dup hash-name ['] intermediates search-wordlist  if  ( name$ xt )
      \ We've already checked this file
      drop                                      ( name$ )
   else                                         ( name$ base$ )
      \ This is the first time we've seen this file;
      \ check its dependencies and remember that we've seen it.
      get-current >r                            ( name$ )
      ['] intermediates set-current             ( name$ )
      2dup hash-name $create                    ( name$ )
      r> set-current                            ( name$ )
      2dup $handle-file                         ( name$ )
   then                                         ( name$ )
   intermediate-action
;

' build-intermediate to intermediate-file
' check-date         to source-file
' source-file        to intermediate-action

: show-name  ( adr len -- )
   over c@ ascii . =  if  \ take expanded prefix ${BP} and any /../ out of path
      cwd$ $pushd                           ( adr len )
      begin " ../" 2over substring?  while  ( rem$ )
         [char] /  left-parse-string        ( rem$ dir$ )
         $chdir!                            ( rem$ )
      repeat                                ( rem$ )
      cwd$ -bp type  ." /"                  ( rem$ )
      popd                                  ( rem$ )
   then                                     ( rem$ )
   \ take literal prefix "${BP}/" out of path
   " ${BP}/" 2over substring?  if  6 /string  then
   type cr
;

: $tag  ( -- )
   true to tagging?
   set-bp$
   ['] build-intermediate to intermediate-file
   ['] show-name     to source-file
   ['] (no-bld-file) to no-bld-file
   ['] 2drop         to intermediate-action
   ['] run-file      to handle-log-file
   ['] run-file      to handle-bld-file

   $handle-file
;
: tag  ( "filename" -- )  safe-parse-word $tag  ;

: $build  ( filename$ -- )

   ['] build-intermediate to intermediate-file
   ['] check-date         to source-file
   ['] (no-bld-file)      to no-bld-file
   ['] run-file           to handle-log-file
   ['] run-file           to handle-bld-file

   $handle-file
;
: build  ( "filename" -- )
   safe-parse-word ['] $build  catch  if
      ." Build aborted" cr  error-exit
   then
;

also extensions definitions
: builder.dic  ( adr len -- )  2drop  ;
: builton.fth  ( adr len -- )  2drop  ;
: fth  ( adr len -- )  source-file  ;
: fc   ( adr len -- )  intermediate-file  ;
: icx  ( adr len -- )  source-file  ;
: dic  ( adr len -- )  intermediate-file  ;
: di   ( adr len -- )  intermediate-file  ;
: gz   ( adr len -- )  intermediate-file  ;
: imz  ( adr len -- )  intermediate-file  ;
: img  ( adr len -- )  intermediate-file  ;
: bin  ( adr len -- )  intermediate-file  ;
: hex  ( adr len -- )  intermediate-file  ;
: sr   ( adr len -- )  intermediate-file  ;
: out  ( adr len -- )  intermediate-file  ;
: aml  ( adr len -- )  intermediate-file  ;

previous definitions

also tags definitions
\ out: filename size mtime(hex) mtime$
: out:
   parse-filename  2dup target-names $replace            ( name$ )
   modtime dup   target-time pop drop  target-time push  ( time )
   0=  if  set-rebuild  then
   skip-line
;

\ in: filename size mtime(hex) mtime$
: in:  parse-filename handle-input skip-line  ;

\ dictionary: dictionary-file-name size mtime(hex) mtime$
: dictionary:
   parse-filename
   2dup dictionary-files $replace
   handle-input skip-line
;

\ host: hostname
: host:  skip-line  ;

\ command: command-name
: command:  0 parse  command-lines $replace   ;

\ args: arg ..
: args:  true abort" Bogus old log file"  ;

\ time: time(hex) time$
\ : time:  skip-line  ;

\ cwd: directory-name
: cwd:  skip-line  ;

\ env: name value
: env:  skip-line  ;

: \   skip-line  ;

\ build-now
: build-now  set-rebuild  fexit  ;

: copyright: skip-line  ;
: purpose:   skip-line  ;

\ : debug-in:  ['] in: (debug  ;

previous definitions
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
