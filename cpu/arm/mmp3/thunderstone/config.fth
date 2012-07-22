create debug-startup
create use-elf

fload ${BP}/cpu/arm/mmp3/thunderstone/addrs.fth
fload ${BP}/cpu/arm/mmp2/hwaddrs.fth

create machine-signature ," TS0"

fload ${BP}/cpu/arm/mmp3/soc-config.fth
