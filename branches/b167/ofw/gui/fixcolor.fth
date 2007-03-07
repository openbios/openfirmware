\ See license at end of file
\ Forth program to modify the color indices used in an 8-bit color image.
\ All it really does is replace all occurences of particular byte values
\ with different values.
\ For use within the Open Firmware GUI, it is often nice to have all the
\ icons use a consistent set of color indices, but some graphics editors
\ do not make it particularly easy to choose which color indices are used
\ for which colors.  This program makes it relatively easy to fix raw image
\ files to use the color indices you want.

\ To use, edit the "mapcolor" function below, putting the indices you want
\ to change in the left column (before the "of") and the substitutions in
\ the column after the "of".
\
\ Then add a "fixcolors" line at the end of the file, naming the desired
\ input (first argument) and output (second argument) files, or uncomment
\ one of the existing lines if it is appropriate.  You can have more than
\ one active (i.e. not commented-out with "\ ") "fixcolors" line if you
\ want to fix several files at once.
\
\ Finally, start Forth on a development system and load this file.

hex
: mapcolor  ( color -- color' )
   case
      24 of  12  endof
      33 of  10  endof
      35 of  10  endof
      36 of  10  endof
      4e of  11  endof
      b2 of  12  endof
      b4 of  12  endof
\      f of  11  endof	 \ For most icons - map white to brown
\      ff of  11  endof
\       5 of  12  endof	 \ For demo-ver.ico
\       5 of  00  endof   \ For flasht.ico
      97 of  10  endof   \ for flp2flsh.ico and flsh2flp.ico
\       8 of  15  endof   \ for install.ico
\      ff of  13  endof	 \ For demo-ver.ico
\      01 of  00  endof   \ for exeunt.ico
\      01 of  14  endof   \ for macos.ico
\      00 of  0f  endof   \ for fwlogo.ico
\      01 of  11  endof   \ for fwlogo.ico
\      03 of  06  endof   \ for macos.ico with bad firmware color map
\       e of  0b  endof  \ for winnt.ico with bad firmware color map
      0f of  13  endof	 \ For most icons - map white to blue background
      48 of  11  endof   \ for exeunt.ico
      49 of  11  endof   \ for exeunt.ico
      fc of  0f  endof   \ for exeunt.ico
      fd of  10  endof   \ for exeunt.ico
\      fe of  0f  endof   \ for exeunt.ico
      fe of  07  endof   \ for flasht.ico
      ff of  0f  endof   \ for flp2flsh.ico and flsh2flp.ico and net2flsh.ico

\      1b of  10  endof	\ For net2flsh.ico
\      1f of  10  endof	\ For net2flsh.ico
\      e3 of   1  endof	\ For net2flsh.ico
\      80 of  12  endof	\ For net2flsh.ico

\      09 of  04  endof	\ For netbsd.ico
\      0c of  01  endof	\ For netbsd.ico
\      0a of  10  endof	\ For netbsd.ico

      dup
   endcase
;
0 value buf
0 value /buf
: fixcolors  ( "in" "out" -- )
   reading
   ifd @ fsize  to /buf
   /buf alloc-mem  to buf
   buf /buf  ifd @  fgets  drop
   ifd @ fclose
   buf /buf  bounds  ?do  i c@  mapcolor  i c!  loop
   writing
   buf /buf ofd @ fputs
   ofd @ fclose
   buf /buf free-mem
;

\ fixcolors help.ico help.icx
\ fixcolors boot_aix.ico boot_aix.icx
\ fixcolors boot_nt.ico boot_nt.icx
\ fixcolors bt_emacs.ico bt_emacs.icx
\ fixcolors config.ico config.icx
\ fixcolors about.ico about.icx
\ fixcolors exit.ico exit.icx
\ fixcolors forth.ico forth.icx
\ fixcolors help.ico help.icx
\ fixcolors showdev.ico showdev.icx
\ fixcolors demo-ver.ico demo-ver.icx
\ fixcolors license.ico license.icx
\ fixcolors logo2.ico logo2.icx
\ fixcolors pwr_fwtm.ico pwr_fwtm.icx
\ fixcolors logo3.ico logo3.icx
\ fixcolors flasht.ico flasht.icx
\ fixcolors flp2flsh.ico flp2flsh.icx
\ fixcolors flsh2flp.ico flsh2flp.icx
\ fixcolors exeunt.ico exeunt.icx
\ fixcolors macos.ico macos.icx
\ fixcolors winnt.ico winnt.icx
\ fixcolors install.ico install.icx
\ fixcolors mactorom.ico mactorom.icx
\ fixcolors mactodsk.ico mactodsk.icx
\ fixcolors restart.ico restart.icx
\ fixcolors ntide.ico ntide.icx
\ fixcolors ntscsi.ico ntscsi.icx
\ fixcolors netbsd.ico netbsd.icx
\ fixcolors net2flsh.ico net2flsh.icx
\ fixcolors fwlogo.ico fwlogo.icx
\ fixcolors funai.ico funai.icx
fixcolors tux.ico tux.icx
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
