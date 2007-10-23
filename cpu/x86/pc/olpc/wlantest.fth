purpose: Wireless LAN auto-wakeup (requires modified WLAN firmware)

0 value patched?
: wackup
   patched? 0=  if
      " /wlan" find-device
      " patch exit link-up? close" evaluate
      dend
      true to patched?
   then

   sci-wakeup

   " /wlan" open-dev >r
   " broadcast-wakeup" r@ $call-method
   r> close-dev

   0
   begin
      " /wlan" open-dev >r
      " autostart" r@ $call-method
      " sleep" r@ $call-method
      r> close-dev
      5 ms
      s
      1+ dup .
      d# 500 ms
   key? until
;
