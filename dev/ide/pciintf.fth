purpose: PCI IDE controller in native mode
copyright: Copyright 1997 Firmworks  All Rights Reserved

\ Use PCI IDE controller into native mode

: int+  ( adr len n -- adr' len' )  encode-int encode+  ;

\ This device has five base registers, used as follows:
\ base	maps
\ 10	1f0-1f7
\ 14	3f6
\ 18	170-177
\ 1c	376
\ 20	bus mastering regs

my-address my-space  encode-phys  0 int+ 0 int+
my-address my-space  h# 100.0010 + encode-phys  encode+  0 int+ 8 int+
my-address my-space  h# 100.0014 + encode-phys  encode+  0 int+ 4 int+
my-address my-space  h# 100.0018 + encode-phys  encode+  0 int+ 8 int+
my-address my-space  h# 100.001c + encode-phys  encode+  0 int+ 4 int+
my-address my-space  h# 100.0020 + encode-phys  encode+  0 int+ h# 10 int+

\ The base address register at offset 24 exists only on Symphony Labs/Winbond
\ parts.  Listing it on other devices can cause address assignment failures.
\ my-address my-space  h# 100.0024 + encode-phys  encode+  0 int+ h# 10 int+

" reg" property

: +map-in  ( offset size -- virt )
   >r my-address rot my-space +  r> " map-in" $call-parent
;
: map-out  ( virt size -- )  " map-out" $call-parent  ;

\ Map the device into virtual address space
: (map)  ( -- base1 dor1 base2 dor2 )
   my-space 9 + dup " config-b@"  $call-parent
       05 or  swap  " config-b!"  $call-parent	\ Native mode

   h# 100.0010 8 +map-in
   h# 100.0014 4 +map-in  2 +
   h# 100.0018 8 +map-in
   h# 100.001c 4 +map-in  2 +

   my-space 4 + dup " config-w@"  $call-parent
        1 or  swap  " config-w!"  $call-parent	\ Enable
;
\ Release the mapping resources used by the device
: (unmap)  ( base1 dor1 base2 dor2 -- )
   my-space 4 + dup " config-w@"  $call-parent
        1 invert and  swap  " config-w!"  $call-parent	\ Disable

   2 - 4 map-out  8 map-out  2 - 4 map-out  8 map-out
;
