purpose: Common code fragment for setting up Geode serial port in early init

   \ Set the UART TX line high - this prevents a low-going glitch that
   \ the receiver interprets as a character.
   100.0000 1010 port-wl   \ Output AUX1 select - UART TX as GPIO for now
        100 1000 port-wl   \ high
        100 1004 port-wl   \ GPIO1 - output enable

   \ The UART init sequence takes 550 uS running from ROM
 [ifdef] use-uart2
   \ cs5536_setup_onchipuart,cs5536_early_setup.c:205.14
   0.00000012.   5140003e set-msr  \ enable UART2

   \ GPIO1 - UART2 TX
   10 1004 port-wl   \ GPIO4 - output enable - UART2 TX
   10 1010 port-wl   \ Output AUX1 select - UART2 TX
    8 1020 port-wl   \ Input enable UART2 RX
    8 1034 port-wl   \ Input AUX1 select - UART2 RX
   0.8070.0003  51400014 set-msr  \ MDD_LEG_IO  UART2 at COM1 address
 [else]
   \ cs5536_setup_onchipuart,cs5536_early_setup.c:205.14
   0.00000012.   5140003a set-msr  \ enable COM1

   \ GPIO1 - UART1 TX
   100 1004 port-wl   \ GPIO1 - output enable
   100 1010 port-wl   \ Output AUX1 select - UART TX
   200 1020 port-wl   \ Input enable UART RX
   200 1034 port-wl   \ Input AUX1 select - UART RX
   0.8007.0003.  51400014 set-msr  \ MDD_LEG_IO  legacy IO
 [then]

   \ uart_init,serial.c
   \ This is a garden-variety 8250 UART setup sequence
    0 3f9 port-wb
    1 3fa port-wb
   83 3fb port-wb  \ DLAB
    1 3f8 port-wb  \ 115200 divisor low
    0 3f9 port-wb  \ 115200 divisor high
    3 3fb port-wb  \ !DLAB
   \ At this point we could send characters out the serial port
   \ End of serial init

   char + 3f8 port-wb  begin  3fd port-rb 40 bitand  0<> until
