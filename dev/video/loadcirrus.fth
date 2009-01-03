purpose: Interior load file for Cirrus video driver

" vga" device-name

fload ${BP}/dev/video/common/defer.fth		\ Defered words
1024x768x16
fload ${BP}/dev/video/controlr/pcimap.fth	\ Generic PCI implementations
fload ${BP}/dev/video/dacs/cirrus.fth
fload ${BP}/dev/video/controlr/vga.fth		\ Load generic VGA routines
fload ${BP}/dev/video/controlr/cirrus.fth	\ Load Cirrus routines
fload ${BP}/dev/video/controlr/cirruspci.fth	\ PCI routines
fload ${BP}/dev/video/common/graphics.fth	\ Graphics and color routines
fload ${BP}/dev/video/common/init.fth		\ Init code
fload ${BP}/dev/video/common/display.fth	\ High level interface code
