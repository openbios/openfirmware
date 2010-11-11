0 0  " "  " /" begin-package
" rtc" name

: set-address  ( -- )  h# d0 2 set-twsi-target  ;
: rtc@  ( reg# -- byte )  set-address  twsi-b@  ;
: rtc!  ( byte reg# -- )  set-address  twsi-b!  ;
: open  ( -- okay )  true  ;
: close  ( -- )  ;
end-package
