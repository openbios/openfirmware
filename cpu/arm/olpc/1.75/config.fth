\ create cl2-a1
create debug-startup
create olpc
create trust-ec-keyboard
create use-null-nvram
create use-elf

fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/1.75/addrs.fth

create machine-signature ," CL2"
