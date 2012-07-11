dev /display

[ifdef] has-dcon
   fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control
[then]

device-end
