purpose: Early-startup subroutine for masked PCI configuration writes

\ masked-config-writes is a specialized subroutine that scans a
\ compact in-line table of PCI configuration register entries.
\ The characteristics of this table are optimized for setting up
\ Via chipsets, in which the setup registers are in PCI configuration
\ space.  Each PCI device/function has numerous registers, so it
\ is worthwhile to optimize for groups of writes to the same
\ device/function.
\
\ Each entry is three bytes - register#, clear_mask, set_mask
\ The register number is the low 8 bits of a PCI configuration
\ register address.  The high bits must already be in %ebp.
\
\ The calculation for each entry is:
\   temp = read_config_byte(address);
\   temp &= ~clear_mask;
\   temp |= set_mask;
\   write_config_byte(address, temp);
\
\ As an optimization, if clear_mask is 0, so that no bits would
\ be cleared, the calculation reduces to:
\   write_config_byte(address, set_mask);
\
\ The last table entry is denoted by a 0 register#.
\ When the table has been completely processed, the subroutine
\ returns to the address just after the table.
\
\ The table is created by macros defined in via/startmacros.fth

\ %ebp contains the config address

label masked-config-writes   \ return address points to the table
   esi pop
   cld
   begin
      al lods                    \ al: register offset
   al al or  0<> while
      al bl mov                  \ bl: register offset

[ifdef] config-to-port80
   h# 77 # al mov  al h# 80 # out
   ebp eax mov  ah al mov  al h# 80 # out
   bl al mov  al h# 80 # out
[then]

      ebp eax mov                \ Config address base
      bl  al  mov                \ Merge in register number
      h# ffff.fffc # ax and      \ Remove low bits
      h# cf8 # dx mov            \ Config address register port #
      ax dx out                  \ Write to config address register

      4 # dl add                 \ DX: cfc
      3 # bl and                 \ Byte offset
      bl  dl add                 \ Config data register port #

      al lods  al not            \ Get AND mask
      al al or  0<>  if          \ Do we need to read-modify-write?
         al ah mov               \ Save mask
         dx al in                \ Get existing value
[ifdef] config-to-port80
   al h# 80 # out
[then]
         ah al and               \ Apply AND mask
         al ah mov
         al lods                 \ Get OR mask
         ah al or                \ Now we have the final value
      else                       \ AND mask is 0 so we don't have to R-M-W
         al lods                 \ Get final value (== OR mask)
      then

[ifdef] config-to-port80
   al h# 80 # out
[then]

      al dx out                  \ Write final value to config data register
   repeat
   esi push
   ret
end-code
   
