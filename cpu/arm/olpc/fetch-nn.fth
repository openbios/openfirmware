purpose: Common code for fetching the NN firmware

\ The macro NN_VERSION, and optionally GET_NN, must be defined externally

\ If there is a GET_NN macro, use it instead of fetching the released version.
" ${GET_NN}" expand$  nip  [if]
   " ${GET_NN}" expand$ $sh
[else]
   " wget -q http://dev.laptop.org/pub/firmware/nn/zForce_Touch_Driver_OLPC_${NN_VERSION}.hex -O nn.hex" expand$ $sh
[then]

\ This forces the creation of an nn.log file, so we don't re-fetch nn.img
writing nn.version
" ${NN_VERSION}"n" expand$  ofd @ fputs
ofd @ fclose
