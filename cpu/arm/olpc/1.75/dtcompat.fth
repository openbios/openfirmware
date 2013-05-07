purpose: Hack to make old kernels boot with new device tree layout

\ The problem this solves is that older OS releases for XO-1.75
\ a) Require ATAGS info instead of flattened device tree (kernel), and
\ b) Require MMC pathnames of the form /sd@d4280000/disk@N instead of
\    the new form /sd/sdhci@d428nnnn/disk (initrd).
\ In order to boot those old OS releases, when we detect an old release,
\ we use ATAGS and rewrite the "bootpath" property in /chosen to the old
\ form.


\ append a fragment to a path in place, returning the new path string
: $append  ( path$ fragment$ -- 'path$ )
   dup >r                       ( path$ fragment$       r: /fragment )
   2over ca+                    ( path$ fragment$ dst   r: /fragment )
   swap cmove                   ( path$                 r: /fragment )
   r> ca+                       ( 'path$ )
   2dup ca+ 0 swap c!           ( 'path$ )
;

\ if "bootpath" (whose underlying storage is load-path) starts with
\ new$ then replace only those characters with old$
: $replaced?  ( old$ new$ -- flag )
   load-path cscount            ( old$ new$ path$ )
   [char] : left-parse-string   ( old$ new$ tail$ head$ )
   2swap 2>r                    ( old$ new$ head$  r: tail$ )
   $=  if                       ( old$  r: tail$ )
      load-path 0               ( old$ path$ )
      2swap $append             ( path$  r: tail$ )
      " :" $append              ( path$  r: tail$ )
      2r> $append               ( path$ )
      2drop true                ( flag )
   else                         ( old$  r: tail$ )
      2r> 4drop false           ( flag )
   then                         ( flag )
;

: fixup-bootpath  ( -- )
   disable-interrupts
   /ramdisk 0=  if  exit  then
   " $bootpath in"n"t"t/sd@"  ramdisk-adr /ramdisk  $sindex  nip  if   ( )
      false to use-fdt?
      " /sd@d4280000/disk@1" " /sd/sdhci@d4280000/disk" $replaced?  ?exit
      " /sd@d4280000/disk@2" " /sd/sdhci@d4280800/disk" $replaced?  ?exit
      " /sd@d4280000/disk@3" " /sd/sdhci@d4281000/disk" $replaced?  ?exit
   then
;

patch fixup-bootpath disable-interrupts linux-fixup
