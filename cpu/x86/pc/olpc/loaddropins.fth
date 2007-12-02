\ Loads the set of drivers that is common to different output formats

   " paging.di"             $add-file
   " ${BP}/cpu/x86/build/inflate.bin"        " inflate"         $add-dropin
   " fw.img"   " firmware"  $add-deflated-dropin

   " ${BP}/dev/usb2/hcd/ohci/build/ohci.fc"	" class0c0310"      $add-deflated-dropin
   " ${BP}/dev/usb2/hcd/ehci/build/ehci.fc"	" class0c0320"      $add-deflated-dropin
   " ${BP}/dev/usb2/device/hub/build/hub.fc"     " usb,class9"      $add-dropin
   " ${BP}/dev/usb2/device/net/build/usbnet.fc"       " usbnet"     $add-deflated-dropin
   " ${BP}/dev/usb2/device/keyboard/build/usbkbd.fc"  " usb,class3,1" $add-dropin
   " ${BP}/dev/usb2/device/serial/build/usbserial.fc" " usbserial"  $add-deflated-dropin
   " ${BP}/dev/usb2/device/storage/build/usbstorage.fc" " usbstorage"   $add-deflated-dropin
   " ${BP}/dev/usb2/device/wlan/build/usb8388.fc" " usb1286,2001"   $add-deflated-dropin
   " usb8388.bin" " usb8388.bin"                                    $add-deflated-dropin

   \ XXX the PCI device IDs should be different for the different CaFe functions
   " ${BP}/dev/olpc/cafenand/build/cafenand.fc"     " class050101"    $add-deflated-dropin
   " ${BP}/dev/olpc/cafecamera/build/cafecamera.fc" " pci11ab,4102"   $add-deflated-dropin

   " ${BP}/dev/mmc/sdhci/build/sdhci.fc"  " pci11ab,4101"   $add-deflated-dropin
   " ${BP}/dev/mmc/sdhci/build/sdmmc.fc"  " sdmmc"          $add-deflated-dropin
   " ${BP}/dev/geode/ac97/build/ac97.fc"       " pci1022,2093"   $add-deflated-dropin

   " builton.fth"                       " probe-"          $add-dropin
   " ${BP}/ofw/fcode/memtest.fth"  " memtest.fth"          $add-deflated-dropin

   " ${BP}/ofw/inet/telnetd.fth"          " telnetd"             $add-deflated-dropin

\    " ${BP}/cpu/x86/pc/olpc/images/warnings.565"  " warnings.565"  $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/lightdot.565"  " lightdot.565"  $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/yellowdot.565" " yellowdot.565" $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/darkdot.565"   " darkdot.565"   $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/lock.565"      " lock.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/unlock.565"    " unlock.565"    $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/plus.565"      " plus.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/minus.565"     " minus.565"     $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/x.565"         " x.565"         $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/sad.565"       " sad.565"       $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/bigdot.565"    " bigdot.565"    $add-deflated-dropin

   " ${BP}/cpu/x86/pc/olpc/images/check.565"    " check.565"     $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/xogray.565"   " xogray.565"    $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/laptop.565"   " nand.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/laptop.565"   " fastnand.565"  $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/ethernet.565" " ethernet.565"  $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/usbkey.565"   " disk.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/wireless.565" " wlan.565"      $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/xo.565"       " xo.565"        $add-deflated-dropin
   " ${BP}/cpu/x86/pc/olpc/images/sd.565"       " sd.565"        $add-deflated-dropin

   " ${BP}/ofw/termemu/gallant.obf"             " font"          $add-deflated-dropin

   " verify.img"                                " verify"        $add-deflated-dropin
   " os.public"                                 " ospubkey"      $add-dropin \ Incompressible
   " fw.public"                                 " fwpubkey"      $add-dropin \ Incompressible
   " fs.public"                                 " fspubkey"      $add-dropin \ Incompressible
   " lease.public"                              " leasepubkey"   $add-dropin \ Incompressible
   " developer.public"                          " develpubkey"   $add-dropin \ Incompressible
