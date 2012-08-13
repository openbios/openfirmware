\ Setup UART configuration 
h# d4018000 to uart-base     \ UART3
devalias com1 /uart@d4018000

dev /uart@d4030000  \ UART1
device-end

dev /uart@d4017000  \ UART2
   " disabled" " status" string-property
device-end

dev /uart@d4018000  \ UART3
device-end

dev /uart@d4016000  \ UART4
   " disabled" " status" string-property
device-end

devalias serial0 /uart@d4030000
devalias serial1 /uart@d4017000
devalias serial2 /uart@d4018000
devalias serial3 /uart@d4016000
