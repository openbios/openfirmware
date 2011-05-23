-1 value mem-fd
: ?open-mem  ( -- )
   mem-fd 0<  if
      2 " /dev/mem" $cstr 8 syscall 2drop  retval  to mem-fd
   then
   mem-fd 0< abort" Can't open /dev/mem; try being root"
;
: mmap  ( phys len -- virt )
   ?open-mem  mem-fd d# 380  syscall  3drop retval
   dup -1 =  abort" mmap failed"
;
: munmap  ( virt len -- )  mem-fd  d# 384  syscall  2drop  ;

: unaligned-mmap  ( phys -- virt )
   dup h# fff and          ( phys phys.lowbits )
   swap h# fff invert and  ( phys.lowbits phys.highbits )
   h# 1000 mmap            ( phys.lowbit virt.highbits )
   +                       ( virt )
;
