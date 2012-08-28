\ Suppress long memory test at final test stage
dev /memory
0 value old-diag-switch?
: not-final-test?  ( -- flag )
   final-test?   if  false exit  then
   smt-test?  if  false exit  then
   old-diag-switch?
;
warning @ warning off
: selftest  ( -- error? )
   diag-switch? to old-diag-switch?
   not-final-test?  to diag-switch?
   selftest
   old-diag-switch? to diag-switch?
;
warning !
device-end

\ Add suspend resume test except in final
[ifndef] mmp3   \ Pending MMP3 suspend/resume implementation
dev /switches
warning @ warning off
: selftest  ( -- error? )
   final-test?  0=  if
      s3-selftest  if  true exit  then
   then
   selftest
;
warning !
device-end
[then]
