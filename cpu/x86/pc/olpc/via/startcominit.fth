label cominit
   \ Turn on frame buffer
   0 3 devfunc
   a1 80 80 mreg   \ This bit must be on so you can talk to the Graphics registers below
   a7 08 08 mreg   \ This one too
   end-table

   \ Turn on I/O space access for display controller
   1 0 devfunc
   04 01 01 mreg
   end-table

   01 3c3 port-wb                    \ Graphics Chip IO port access on
   10 3c4 port-wb   01 3c5 port-wb   \ Graphics Chip register protection off

   \ The preceding setup was all so that we can write the following bit.
   \ It seems silly to have a bit that controls the UART in the graphics
   \ chip sequencer register block (additional editorializing elided...).

   78 3c4 port-wb   3c5 port-rb              \ Old value in al
   h# 80 # al or  al bl mov                  \ Set south module pad share enable
   78 3c4 port-wb   3c5 # dx mov  bl al mov  al dx out

   \ If the SERIAL_EN jumper is installed, routing the external pin to
   \ the UART; otherwise leave it connected to the VCP port.

   acpi-io-base 48 +  port-rb  h# 10 # al test  0=  if

      d# 17 0 devfunc
      \ The following is for UART on VCP port
      46 c0 40 mreg
      \ The following is for UART on DVP port
      \ 46 c0 c0 mreg
      end-table

   then
   
   d# 17 0 devfunc
   \ Standard COM2 and COM1 IRQ routing
   b2 ff 34 mreg

   \ For COM1 - 3f8 (ff below is 3f8 3 >> 80 or )

   b0 30 10 mreg
   b4 ff ff mreg   \ 3f8 3 >>  80 or  - com base port

   \ For COM2 - 2f8 (df below is 2f8 3 >> 80 or )
   \ b0 30 20 mreg
   \ b5 ff df mreg
   end-table

   init-com1   \ The usual setup dance for a PC UART...

   ret
end-code
