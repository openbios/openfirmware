create debug-startup
create olpc
create trust-ec-keyboard
create use-null-nvram
create use-elf
create olpc-cl3

fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

create machine-signature ," CL3"
