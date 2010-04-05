purpose: Special low power battery charge monitor 
\ See license at end of file

\ Need the comma to be compatible with olpc-pwr-log stuff
: >sd,
   base @ >r decimal
   dup abs <# " ," hold$ u#s swap sign u#>
   r> base !
;

: >sd.dd,  ( n -- formatted )
   base @ >r  decimal
   dup abs <# " ," hold$ u# u# [char] . hold u#s swap sign u#>
   r> base !
;

0 value start-acr
d# 60 value (wake-delay)
d# 0  value wake-delay

: setup-rtc-wake ( delay -- )
   0 acpi-l@ h# 400.0000 or 0 acpi-l!
   ['] noop " set-alarm" clock-node @ $call-method
;

: finish-rtc-wake ( -- ) 0 acpi-l@ h# 400.0000 invert and 0 acpi-l! ;

: bat-charge-dataf@
      0 logstr c!
      time&date >unix-seconds >sd, logstr $cat
      soc >sd, logstr $cat
      uvolt@ dup >sd, logstr $cat
      cur@ dup >sd, logstr $cat
      bat-temp >sd, logstr $cat
      bat-acr@ s16>s32 dup >sd, logstr $cat
      start-acr - bg-acr>mAh >sd.dd, logstr $cat
;

h# 100 buffer: fname-buf 
 
:  charge-log-append ( adr len -- )
      fname-buf $append-open
      ftype
      fcr
      ofd @ fclose
;

: charge-log ( "filename" -- ) \ filename is optional
   ['] safe-parse-word catch if 
      fname-buf place 
   else 
   " sd:\charge.log" fname-buf place
   then  
   ." Logging to: " fname-buf count type cr
   fname-buf $new-file  
   ofd @ fclose

   " chg_log Ver: 1.0" charge-log-append
   " <StartData>" charge-log-append   \ This makes us compatible with the processing scripts for use with olpc-pwr-log

   \ Allow for suspend to be super low power
   dcon-power-off
   wlan-freeze

   sci-wakeup
   bat-acr@ s16>s32 to start-acr
   begin
      bat-charge-dataf@
      \ Even though we have no screen still do console output
      \ So it shows up on the serial port.
      logstr count type cr
      logstr count charge-log-append
      wake-delay setup-rtc-wake
      \ We don't want to do video restore. Only usb 
      suspend-usb
      s3
      resume-usb
      finish-rtc-wake
      key?
   until key drop
;

: watch-charge ( -- )
   \ 5 seconds is the default unless the user sets wake-delay
   wake-delay 0= if 
      d# 5 to (wake-delay) 
      ." Using default delay" cr
      ." Set wake-delay fo a different value" cr
   else
      wake-delay to (wake-delay)
   then
   (wake-delay)
   ." Sampling every " .d ." seconds" cr
   sci-wakeup
   bat-acr@ s16>s32 to start-acr
   begin
      bat-charge-dataf@
      logstr count type cr

\      wake-delay setup-rtc-wake
\      s3-suspend
\      finish-rtc-wake

\     RTC wake seems flaky.
\     use EC for now (only works on 1.5)
      (wake-delay) d# 1000 * h# 36 ec-cmd-l! 
      s3-suspend
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

