\ Setup UART configuration 
h# d4018000 to uart-base     \ UART3
devalias com1 /uart@d4018000

dev /uart@d4030000  \ UART1
   0 " linux,unit#" integer-property
device-end

dev /uart@d4017000  \ UART2
   " disabled" " status" string-property
device-end

dev /uart@d4018000  \ UART3
   1 " linux,unit#" integer-property
device-end

dev /uart@d4016000  \ UART4
   " disabled" " status" string-property
device-end
