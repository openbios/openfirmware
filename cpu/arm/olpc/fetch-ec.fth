purpose: Common code for fetching the EC microcode

\ The macros EC_PLATFORM, EC_VERSION, and optionally GET_EC, must be defined externally

\ If there is a GET_EC macro, use it instead of fetching the released version.
" ${GET_EC}" expand$  nip  [if]
   " ${GET_EC}" expand$ $sh
[else]
   " wget -q http://dev.laptop.org/pub/ec/${EC_PLATFORM}-${EC_VERSION}.img -O ec.img" expand$ $sh
[then]

\ This forces the creation of an ec.log file, so we don't re-fetch ec.img
writing ec.version
" ${EC_VERSION}"n" expand$  ofd @ fputs
ofd @ fclose
