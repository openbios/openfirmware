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

   " ${BP}/dev/geode/ac97/build/ac97.fc"       " pci1022,2093"   $add-deflated-dropin

   " builton.fth"                       " probe-"          $add-dropin
   " ${BP}/ofw/fcode/memtest.fth"  " memtest.fth"          $add-deflated-dropin

   " ${BP}/ofw/inet/telnetd.fth"          " telnetd"             $add-deflated-dropin

   " ${BP}/ofw/termemu/gallant.obf"             " font"          $add-deflated-dropin
