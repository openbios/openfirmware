: .3r  space <# u# u# u#> type  ;
: dump-ec  ( adr len -- )
   dup h# 10 <  if
      over 4 u.r ." :  "   bounds do i ec@ .3r loop  cr
   else
      bounds ?do
         i 4 u.r  ." :  "
         i h# 10  bounds  ?do  i ec@ .3r loop  cr
      h# 10 +loop
   then
;
: dump-ec-regs  ( -- )
." GPIOO  "  fc00 4 dump-ec
." GPIOE  "  fc10 6 dump-ec
." GPIOD  "  fc20 6 dump-ec
." GPIOIN "  fc30 7 dump-ec
." GPIOPU "  fc40 6 dump-ec
." GPIOOD "  fc50 4 dump-ec
." GPIOIE "  fc60 7 dump-ec
." GPIOM  "  fc70 1 dump-ec
." KBC    "  fc80 7 dump-ec
." PWM    "  fe00 e dump-ec
." GPT    "  fe50 a dump-ec
." SPI    "  fea0 10 dump-ec
." WDT    "  fe80 6 dump-ec
." LPC    "  fe90 10 dump-ec
." PS2    "  fee0 7 dump-ec
." EC     "  ff00 20 dump-ec
." GPWUEN "  ff30 4 dump-ec
." GPWUPF "  ff40 4 dump-ec
." GPWUPS "  ff50 4 dump-ec
." GPWUEL "  ff60 4 dump-ec
;
