purpose: Hack to make old kernels boot with new device tree layout

\ The problem this solves is that older OS releases for XO-1.75
\ a) Require ATAGS info instead of flattened device tree (kernel), and
\ b) Require MMC pathnames of the form /sd@d4280000/disk@N instead of
\    the new form /sd/sdhci@d428nnnn/disk (initrd).
\ In order to boot those old OS releases, when we detect an old release,
\ we use ATAGS and rewrite the "bootpath" property in /chosen to the old
\ form.


\ If "bootpath" (whose underlying storage is load-path) matches newpath$,
\ replace it with oldpath$ .
: $replaced?  ( oldpath$ newpath$ -- flag )
   load-path cscount  substring?  if   ( oldpath$ )
      load-path place-cstr             ( )
      true                             ( flag )
   else                                ( oldpath$ )
      2drop false                      ( flag )
   then                                ( flag )
;

: fixup-bootpath  ( -- )
   disable-interrupts
   /ramdisk 0=  if  exit  then
   " $bootpath in"n"t"t/sd@"  ramdisk-adr /ramdisk  $sindex  nip  if   ( )
      false to use-fdt?
      " /sd@d4280000/disk@1:/" " /sd/sdhci@d4280000/disk" $replaced?  ?exit
      " /sd@d4280000/disk@2:/" " /sd/sdhci@d4280800/disk" $replaced?  ?exit
      " /sd@d4280000/disk@3:/" " /sd/sdhci@d4281000/disk" $replaced?  ?exit
   then
;

patch fixup-bootpath disable-interrupts linux-fixup
