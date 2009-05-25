purpose: Setup for Flash ROM access
copyright: Copyright 1995-2001 Firmworks.  All Rights Reserved.

h# 10.0000 to /flash

0 value flashbase

headerless
: (fctl!)   ( n a -- )  flashbase +  rb!  ;  ' (fctl!)  to fctl!
: (fdata!)  ( n a -- )  flashbase +  rb!  ;  ' (fdata!) to fdata!
: (fc@)     ( a -- n )  flashbase +  rb@  ;  ' (fc@)    to fc@

headers
: open-flash  ( -- )
   flashbase 0=  if
      rom-pa /flash  root-map-in  to flashbase
   then
;
: close-flash  ( -- )
   flashbase /flash  root-map-out  0 to flashbase
;
' open-flash to enable-flash-writes

