\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: bootparm.fth
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
id: @(#)bootparm.fth 3.39 06/04/25
purpose: Implements the boot command - parses arguments, etc.
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

\ Forth support for the booting process

\ Booting entries:
\ a) User types  "boot ....."
\ b) The client program invokes the "reboot" client interface service
\
\ We need a flag indicating whether or not to reset the machine.
\

headers
\needs load-base 0  config-int load-base	\ The default value can be changed later

variable file-size
: loaded  ( -- adr len )  load-base file-size @  ;

headerless
: !load-size  ( len -- )  file-size !  ;

d# 256 buffer: path-buf
headers
' path-buf  " bootpath" chosen-string
headerless
d# 256 buffer: args-buf
headers
' args-buf  " bootargs" chosen-string

0 value opened-ih

partial-headers
defer ?show-device  ( adr len -- adr len )   ' noop is ?show-device

defer load-started  ' noop to load-started
defer load-done     ' noop to load-done

defer load-path
' path-buf is load-path

headerless
: limit-255  ( adr len -- adr len )
   dup d# 255 >  if
      ." Warning: limiting string length to 255 characters" cr
      drop d# 255
   then
;

: (boot-read)  ( adr len -- )
   opened-ih  if                        ( adr len )
      2drop  opened-ih  0 to opened-ih  ( ihandle )
   else                                 ( adr len )
      ?show-device  open-dev            ( ihandle | 0 )
   then                                 ( ihandle | 0 )
   ?dup  0=  if
      ( print-probe-list )
      true abort" "r"nCan't open boot device"r"n"
   then                                         ( fileid )
   dup ihandle>devname limit-255 load-path place-cstr drop ( fileid )
   >r                                           ( )
   load-started
   0 !load-size  load-base                      ( load-adr )
   " load" r@  ['] $call-method  catch ?dup  if ( load-adr adr len fid err# )
      .error
      2drop 2drop  r> close-dev                 ( )
      true abort" "r"nBoot load failed"r"n"     ( )
   then                                         ( file-size )
   !load-size                                   ( )
   load-done                                    ( )
   r> close-dev                                 ( )
;

defer ?inflate-loaded  ' noop to ?inflate-loaded
: boot-read  ( adr len -- )  (boot-read) ?inflate-loaded  ;

headerless
: default-device  ( -- $devname )
   diagnostic-mode?  if  diag-device  else  boot-device  then

   strip-blanks                       ( devnames$ )
   begin                              ( devnames$ )
      bl left-parse-string            ( right$ left$ )
      2swap strip-blanks  dup >r      ( left$ right$ ) ( r: right-len )
      2swap strip-blanks              ( right$ left$ )
      r>                              ( right$ left$ right-len )
   while                              ( right$ left$ )
      ?show-device                    ( right$ left$ )
      2dup open-dev to opened-ih      ( right$ left$ )
      opened-ih  if                   ( right$ left$ )
	 2swap 2drop  exit            ( left$ )
      else                            ( right$ left$ )
	 2drop                        ( right$ )
      then                            ( right$ )
   repeat                             ( right$ )
   2swap 2drop                        ( devname$ )
   strip-blanks                       ( devname$ )
;
: default-file  ( -- file&args$ )
   diagnostic-mode?  if  diag-file  else  boot-file  then
   strip-blanks
;

headerless
\ Gets the boot command line, either user-specified or default.
: parse-boot-command  ( cmd-str -- file-str device-str )
   -leading            \ Skip leading blanks   ( cmd-str )

   dup 0=  if
      \ Whole thing is null; use default file and default device
      2drop  default-file  default-device  ?expand-alias
      2swap -leading  2swap -leading  exit
   then					       ( cmd-str )

   2dup  bl left-parse-string                  ( cmd-str rem-str 1st-str )

   \ We know that 1st-str is not null because we have already checked
   \ for the entire string = null

   over c@  ascii /  =  if                     ( cmd-str rem-str 1st-str )
      \ Explicit pathname in first word; use it as the device and the
      \ rest of the command line as the file
      2rot 2drop                               ( file-str device-str )
   else                                        ( cmd-str rem-str 1st-str )
      aliased?  if                             ( cmd-str rem-str alias$ )
         \ First word is alias; expand it as the device and use the
	 \ rest of the command line as the file.
         2rot 2drop                            ( file-str device-str )
      else                                     ( cmd-str rem-str 1st-str )
         \ First word is neither a path nor an alias; use the default
	 \ device as the device and the entire command line as the file.
         2drop 2drop                           ( file-str )
         default-device  ?expand-alias         ( file-str device-str )
      then
   then                                        ( file-str device-str )

   2 pick  0=  if
      \ No file name given; use the default file instead
      2swap 2drop  default-file 2swap
   then                                        ( file-str device-str )

   2swap -leading  2swap -leading              ( file-str device-str )
;


headerless
create boot-file-not-found ," The attempt to load a boot image failed."

: ?show-message  ( adr len -- )
[ifdef] (silent-mode?   (silent-mode?  if  2drop exit  then  [then]
   progress progress-done
;

\ Loads the file specified by the boot command line string at adr,len
headers
: $boot-read  ( cmd-str -- )
   parse-boot-command                         ( file-str device-str )

   collect(
   ." Boot device: "      2dup  type          ( file-str device-str )
   ."   Arguments: "  2over type              ( file-str device-str )
   )collect ?show-message                     ( file-str device-str )

   2swap limit-255 args-buf  place-cstr drop  ( device-str )

   boot-read                                  ( )
;

: boot-load  ( cmd-str -- )
   state-valid off  restartable? off           ( cmd-str )
   cleanup                                     ( cmd-str )

   $boot-read

   \ The "memory-clean?" function, if any, should be done in init-program
   \ " memory-clean?" memory-node @  $call-method  off

   loaded dup 0<=  if  boot-file-not-found  throw  then  sync-cache

   " init-program" $find  if  execute  else  2drop  then
;

headerless

: boot-getline  \ command line  ( -- adr len )
   -1 parse  -trailing  ( adr len )
;

0 0 2value reboot-cmd$

headers

: go  ( -- )
   init-security  restartable? @  if  go exit  then
   loaded  dup  if  'execute-buffer  execute  else  2drop  then
;

\ Reads the first level boot file, but doesn't jump to it.
: load  \ boot-spec  ( -- )
   " load" to reboot-cmd$
   boot-getline  boot-load
;

headerless

: $append  ( adr len -- )
   \ Insert a space to separate the strings if both are non-empty
   dup 0<>  "temp c@ 0<>  and  if  "  " "temp $cat  then   ( adr len )

   \ Append the string to the end of the saved one
   "temp $cat
;

\ $restart never returns to its caller.  It resets the machine, leaving
\ hints in a system-dependent "safe" location so that the system will reboot
\ itself with the specified string.

: $restart  ( tail$ mid$ head$ -- )
   switch-string  "temp place     ( tail$ mid$ )
   $append  $append  "temp count  ( adr len )

   stdout-line# stdout-column#    ( adr len line col )
   save-reboot-info               (  )
   reset-all
;
: $reboot  ( arg$ dev$ -- )  reboot-cmd$  $restart  ;

: reboot-same  ( -- )  args-buf cscount  path-buf cscount  $reboot  ;

: ?boot-password  ( adr len -- adr len )
   security-mode  case                           ( adr len )
      1  of  dup 0<>    endof   \ Need password only for non-default boot
      2  of  true       endof   \ Always need password
      ( default ) false         \ Don't need password
   endcase                                       ( adr len password-needed? )
   if  password-okay?  0=  if  quit  then  then  ( adr len )
;

headers

: $boot  ( adr len -- )
   " boot" to reboot-cmd$
   already-go?  if  null$ $reboot  then

   ?boot-password  boot-load  go
;

\ Reads and executes the first level boot file; executed by the user
: boot  \ boot-spec  ( -- )
   boot-getline  $boot
;

headerless

\ ?reboot executes after the machine is reset and has come back up.
\ If the reset resulted from a reboot, ?reboot will attempt to boot
\ using the parameters that were saved  by boot-reset

partial-headers
defer interrupt-auto-boot?  ' false to interrupt-auto-boot?

headerless
: safe-evaluate  ( adr len -- )
   ['] include-buffer  catch  ?dup  if  nip nip .error  then   ( )
;
: do-auto-boot ( -- )
   auto-boot?  if
      interrupt-auto-boot?  0=  if  boot-command  safe-evaluate  then
   then
;

partial-headers
: auto-boot  ( -- )
   reboot?  if
      get-reboot-info                              ( bootcmd$ line# column# )

      \  Cursor position is restored in fwritestr.fth
      2drop                                        ( bootcmd$ )

      collect(
      ." Rebooting with command: "  2dup type      ( bootcmd$ )
      )collect  ?show-message                      ( bootcmd$ )

      safe-evaluate                                ( )
      exit
   then

   " boot-" do-drop-in
   do-auto-boot
   " boot+" do-drop-in
;

\ Execute this if auto-boot is determined to be undesireable --
\ for example, if a selftest operation finds a fatal system error.
: suppress-auto-boot  ( -- )  ['] true to interrupt-auto-boot?  ;

headers
also client-services definitions
: boot  ( cstr -- )  cscount  null$ $reboot  ;
: restart  ( cstr -- )  cscount  null$ null$  $restart  ;
previous definitions
