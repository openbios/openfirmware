\ create cl2-a1
create cl2-a2
create debug-startup
create olpc
create trust-ec-keyboard
create use-null-nvram

fload ${BP}/cpu/arm/olpc/1.75/addrs.fth
fload ${BP}/cpu/arm/mmp2/hwaddrs.fth

create machine-signature ," CL2"
