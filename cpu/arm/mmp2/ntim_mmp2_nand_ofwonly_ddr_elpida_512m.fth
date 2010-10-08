\ Marvel Trusted Image Module image creation script for
\ MMP2 platform with 512M of Elpida RAM
\ Running OFW directly, with no intermediate loader

tim: 00030102 0 Sky! PXA688
flash: NAN'6
timh:  TIMH        0 d1020000
image: WTMI     1000 d1000000 /c/Documents and Settings/Mitch Bradley/My Documents/OLPC/Marvell/alpha1_sdcard_update/WtmUnresetPJ4.bin
image: OBMI    80000        0 /home/wmb/ofw.test/cpu/arm/mmp2/build/ofw.rom
reserved:

  fload ddr_elpida_512m.fth
  term:
end-reserved
end-tim

save-image: nand_ofwonly.img
