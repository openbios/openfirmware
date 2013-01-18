purpose: Device node for GALCORE graphics accelerator

h# d420.d000 constant gpu-pa  \ Base of GPU
h#      1000 constant /gpu

dev /
new-device
   " gpu" device-name
   " mrvl,galcore" +compatible
   gpu-pa /gpu reg
   d# 0 encode-int  2 encode-int encode+ " interrupts" property
   " /interrupt-controller/interrupt-controller@1c0" encode-phandle " interrupt-parent" property

   " galcore 3D" encode-string " galcore 2D" encode-string  encode+ " interrupt-names" property

   " /pmua" encode-phandle d# 11 encode-int encode+ " clocks" property
   " GCCLK" " clock-names" string-property
finish-device
device-end
