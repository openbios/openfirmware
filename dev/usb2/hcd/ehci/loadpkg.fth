purpose: Load file for the EHCI HCD files

\ Generic HCD stuff
fload ${BP}/dev/usb2/align.fth			\ DMA memory allocation
fload ${BP}/dev/usb2/pkt-data.fth		\ USB packet definitions
fload ${BP}/dev/usb2/pkt-func.fth		\ USB descriptor manipulations
fload ${BP}/dev/usb2/hcd/hcd.fth		\ Common HCD methods
fload ${BP}/dev/usb2/hcd/error.fth		\ Common HCD error manipulation
fload ${BP}/dev/usb2/hcd/dev-info.fth		\ Common internal device info

\ EHCI HCD stuff
fload ${BP}/dev/usb2/hcd/ehci/ehci.fth		\ EHCI methods
fload ${BP}/dev/usb2/hcd/ehci/qhtd.fth		\ EHCI QH & qTD manipulations
fload ${BP}/dev/usb2/hcd/ehci/control.fth	\ EHCI control pipe operations
fload ${BP}/dev/usb2/hcd/ehci/bulk.fth		\ EHCI bulk pipes operations
fload ${BP}/dev/usb2/hcd/ehci/intr.fth		\ EHCI interrupt pipes operations
fload ${BP}/dev/usb2/hcd/control.fth		\ Common control pipe API

\ EHCI usb bus probing stuff
fload ${BP}/dev/usb2/vendor.fth			\ Vendor/product table manipulation
fload ${BP}/dev/usb2/device/vendor.fth		\ Supported vendor/product tables
fload ${BP}/dev/usb2/hcd/fcode.fth		\ Load fcode driver for child
fload ${BP}/dev/usb2/hcd/device.fth		\ Make child node & its properties
fload ${BP}/dev/usb2/hcd/ehci/probehub.fth	\ USB 2.0 hub specific stuff
fload ${BP}/dev/usb2/hcd/ehci/probe.fth		\ Probe root hub
fload ${BP}/dev/usb2/hcd/probehub.fth		\ Generic hub probing
