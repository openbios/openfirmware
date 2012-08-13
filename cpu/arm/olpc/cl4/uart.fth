\ Setup UART configuration 
h# d4017000 to uart-base     \ UART2
devalias com1 /uart@d4017000

dev /uart@d4030000  \ UART1
   " disabled" " status" string-property
device-end

dev /uart@d4017000  \ UART2
device-end

dev /uart@d4018000  \ UART3
   " disabled" " status" string-property
device-end

dev /uart@d4016000  \ UART4
   " disabled" " status" string-property  \ Used for touchscreen BSL
device-end

devalias serial2 /uart@d4017000
