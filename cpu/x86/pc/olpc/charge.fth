purpose: Special low power battery charge monitor 
\ See license at end of file

\ Need the comma to be compatible with olpc-pwr-log stuff

: >sd,
   <# " ," hold$ u#s u#>
;

: >sd.dd,  ( n -- formatted )
   base @ >r  decimal
   dup abs <# " ," hold$ u# u# [char] . hold u#s rot sign u#>
   r> base !
;

:  bat-log-append ( adr len -- )
   " sd:\charge.log" $append-open   \ hardcode the path for now
      ftype
      fcr
      ofd @ fclose
;


0 value start-acr
d# 15 value wake-delay

: bat-charge-dataf@
      base @ >r  decimal
      0 logstr c!
      time&date >unix-seconds >sd, logstr $cat
      soc >sd, logstr $cat
      uvolt@ dup >sd, logstr $cat 100 /         ( V__.1mV ) 
      cur@ dup >sd, logstr $cat   100 /         ( V_.1mV I__.1mA )
       * drop                            ( W_mW ) 
      bat-temp >sd, logstr $cat                 
      bat-acr@ s16>s32 dup >sd, logstr $cat     
      start-acr - bg-acr>mAh >sd.dd, logstr $cat
      r> base !
;

: bat-charge-log ( -- )
   " sd:\charge.log" $new-file      \ Make sure the file exists and is empty.
   ofd @ fclose

   " chg_log Ver: 1.0" bat-log-append
   " <StartData>" bat-log-append   \ This makes us compatible with the processing scripts for use with olpc-pwr-log

   \ Allow for suspend to be super low power
   dcon-power-off
   wlan-freeze

   sci-wakeup
   bat-acr@ s16>s32 to start-acr
   begin
      bat-charge-dataf@
      logstr count type cr
      logstr count bat-log-append
      0 acpi-l@ h# 400.0000 or  0 acpi-l!  \ Enable RTC SCI
      ['] noop  wake-delay " set-alarm" clock-node @ $call-method
      s3
      0 0 acpi-l!                          \ Disable RTC SCI
      key?
   until key drop
;


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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

