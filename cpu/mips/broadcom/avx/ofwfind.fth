purpose: Start redundant OFW code
copyright: Copyright 2001 Firmworks.  All Rights Reserved.

transient
: delay-ms  ( ms -- )
   d# 100.0000 * d# 830 + d# 1660 / " t0 set" evaluate
   " begin  t0 0 = until  t0 -1 t0 addi" evaluate
;
resident

label compute-chksum  ( v0: ofw base -- v1: chksum )
   /rom t3 set
   0 v1 set

   begin
      t3 -1 t3 addi
      v0 t3 t2 add
      t2 0  t0 lbu
      t0 v1 v1 add
   t3 0 =  until
   nop

   ra jr  nop
end-code

label new-ofw-ok?  ( v0: current ofw base -- v0: 0 | new ofw base )
   ra t7 move			\ Save return address

carret ?report
linefeed ?report
ascii c ?report
ascii h ?report
ascii k ?report
ascii s ?report
ascii u ?report
ascii m ?report
ascii . ascii . ascii . ?report ?report ?report

   h# 8.0000 t0 set
   v0 t0 v0 or			\ new ofw base

   compute-chksum  bal nop
   v1 h# ff v1 andi
   h# a5 t0 set
   v1 t0 <>  if  nop  
      0 v0 set
   then

   t7 jr  nop
end-code

\ If currently running from backup OFW and new OFW is found sanguine,
\ ?jump-to-new-ofw will not return to the caller.  Instead, control
\ will be transferred to the new OFW reset entry point.  Otherwise,
\ ?jump-to-new-ofw will return to the caller to continue OFW startup.

\ Preserve ra in case we return to the caller.

label ?jump-to-new-ofw  ( -- )
   ra t8 move			\ Save return address

   here 4 + bal  nop
   ra t1 move			\ Address of instruction

   h# 8.0000 t0 set
   t1 t0 t1 and

   t1 0 =  if  nop		\ Running from backup OFW now
      h# fff0.0000 t0 set
      ra t0 v0 and		\ Current ofw base
      new-ofw-ok?  bal nop	\ Check if new ofw is ok
      v0 0 =  if  nop		\ No good new ofw found, use backup
         ascii O ?report
         ascii L ?report
         ascii D ?report
      else nop
         ascii N ?report
         ascii E ?report
         ascii W ?report
         d# 10 delay-ms
         v0 jr nop		\ Jump to new ofw
      then
   then

   t8 jr  nop			\ Return to caller
end-code

