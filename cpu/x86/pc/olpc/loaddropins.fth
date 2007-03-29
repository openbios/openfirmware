\ Loads the set of drivers that is common to different output formats

   " paging.di"             $add-file
   " ${BP}/cpu/x86/build/inflate.bin"        " inflate"         $add-dropin
   " fw.img"   " firmware"  $add-deflated-dropin

   " ${BP}/dev/usb2/hcd/ohci/build/ohci.fc"	" class0c0310"      $add-deflated-dropin
   " ${BP}/dev/usb2/hcd/ehci/build/ehci.fc"	" class0c0320"      $add-deflated-dropin
   " ${BP}/dev/usb2/device/hub/build/hub.fc"     " usb,class9"      $add-dropin
   " ${BP}/dev/usb2/device/net/build/usbnet.fc"       " usbnet"     $add-deflated-dropin
   " ${BP}/dev/usb2/device/keyboard/build/usbkbd.fc"  " usb,class3" $add-dropin
   " ${BP}/dev/usb2/device/serial/build/usbserial.fc" " usbserial"  $add-deflated-dropin
   " ${BP}/dev/usb2/device/storage/build/usbstorage.fc" " usbstorage"   $add-deflated-dropin

   \ XXX the PCI device IDs should be different for the different CaFe functions
   " ${BP}/dev/olpc/cafenand/build/cafenand.fc"     " class050101"    $add-deflated-dropin
   " ${BP}/dev/olpc/cafecamera/build/cafecamera.fc" " pci11ab,4102"   $add-deflated-dropin

   " ${BP}/dev/mmc/sdhci/build/sdhci.fc"  " pci11ab,4101"   $add-dropin
   " ${BP}/dev/mmc/sdhci/build/sdmmc.fc"  " sdmmc"          $add-dropin
[ifndef] lx-devel
   " ${BP}/dev/geode/nandflash/build/nandflash.fc" " nand5536"   $add-deflated-dropin
[then]
   " ${BP}/dev/geode/ac97/build/ac97.fc"       " pci1022,2093"   $add-deflated-dropin

   " builton.fth"                       " probe-"          $add-dropin
   " ${BP}/ofw/fcode/memtest.fth"  " memtest.fth"          $add-deflated-dropin

   " ${BP}/ofw/inet/telnetd.fth"          " telnetd"             $add-deflated-dropin

\   " ${BP}/ofw/linux/logos.bmp"          " oslogo.bmp"     $add-deflated-dropin
\   " ${BP}/ofw/linux/logom16e.bmp"       " error.bmp"      $add-deflated-dropin
\   " ${BP}/ofw/linux/logom16c.bmp"       " timeout.bmp"    $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/olpclogo.565" " olpc.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/laptop.565"   " nandflash.565" $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/network.565"  " network.565"   $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/usbkey.565"   " disk.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/wireless.565" " wireless.565"  $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/xo.565"       " xo.565"        $add-deflated-dropin
