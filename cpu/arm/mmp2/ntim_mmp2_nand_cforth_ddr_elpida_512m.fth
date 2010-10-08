\ Marvel Trusted Image Module image creation script for
\ MMP2 platform with 512M of Elpida RAM
\ Running CForth from the security processor

tim: 00030102 0 Sky! PXA688
flash: NAN'6
timh:  TIMH      0 d1020000
image: OBMI    400        0 dummy.img
image: WTMI    404 d1000000 /home/wmb/OLPC/1.75/cforth-from-0xc0000.img
reserved:
  tbrx: 00020000
    transfer: TIMH d1020000
  end-package
  fload ddr_elpida_512m.fth
  term:
end-reserved
end-tim

save-image: nand_cforth.img
