purpose: Load file for additional core routines

\ Load code to recognize client program header
\ fload ${BP}/ofw/core/go.fth		\ Initial program state

fload ${BP}/ofw/core/bootdev.fth	\ S boot command parser
fload ${BP}/ofw/core/bootparm.fth	\ S boot command parser

\ fload ${BP}/ofw/core/dload.fth	\ Diagnostic loading

fload ${BP}/ofw/core/callback.fth	\ Client callbacks

fload ${BP}/ofw/core/deblock.fth	\ Block-to-byte conversion package

fload ${BP}/ofw/core/dl.fth		\ Diagnostic loading
fload ${BP}/ofw/core/dlfcode.fth	\ Serial line loading

fload ${BP}/ofw/core/instcons.fth	\ install-console

[ifndef] custom-banner
fload ${BP}/ofw/core/banner.fth		\ Default banner
[then]
