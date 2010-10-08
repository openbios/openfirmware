\ Marvel Trusted Image Module image creation script for
\ MMP2 platform with 512M of Elpida RAM
\ Running uboot

tim: 00030102 0 Sky! PXA688
flash: NAN'6
timh:  TIMH      0 d1020000
image: OBMI  80000        0 /c/Documents and Settings/Mitch Bradley/My Documents/OLPC/Marvell/alpha1_sdcard_update/MMP2_JASPER_LOADER_3_2_15.bin
image: WTMI  c0000 d1000000 /c/Documents and Settings/Mitch Bradley/My Documents/OLPC/Marvell/alpha1_sdcard_update/WtmUnresetPJ4.bin
image: OSLO 100000   100000 /c/Documents and Settings/Mitch Bradley/My Documents/OLPC/Marvell/alpha1_sdcard_update/u-boot.bin
reserved:
  tbrx: 00020000
    transfer: TIMH d1020000
  end-package
  fload ddr_elpida_512m.fth
  term:
end-reserved
end-tim

save-image: nand_from_forth.img
