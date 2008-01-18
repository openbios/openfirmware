purpose: Startup hacks for Intel 945 chipset

create use-pata
\ create use-sata
: ?configure-i945  ( -- )
[ifdef] use-pata
   h# f900 config-l@ h# 27df8086 =  if  \ i945 IDE
      h# 8000 h# f940 config-w!   \ Turn on IDE decode
      h# fa00 config-l@ h# 27c08086 =  if  \ i945 SATA
         h# 8f h# fa09 config-b!     \ Prevent the legacy mode driver from binding
         h# 0000 h# fa40 config-w!   \ Turn off IDE decode
      then
   then
[then]
[ifdef] use-sata
   h# fa00 config-l@ h# 27c08086 =  if  \ i945 SATA
      h# 8000 h# fa40 config-w!   \ Turn on IDE decode
      h# 8a h# fa09 config-b!     \ Allow the legacy mode driver to bind
\     h# 00 h# fa90 config-b!     \ IDE mode using SATA for all devices
      h# 01 h# fa90 config-b!     \ IDE mode using PATA as primary, SATA as secondary
\     h# 02 h# fa90 config-b!     \ IDE mode using SATA as primary, PATA as secondary
   then
[then]
;
stand-init: I945
   ?configure-i945
;
