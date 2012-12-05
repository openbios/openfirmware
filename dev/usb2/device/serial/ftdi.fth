purpose: Driver for FTDI USB serial chips

8 buffer: ftdi-buf

0 value ftdi-port   \ 0 for single-interface devices and SIOA, 1 for SIOB, 2 for parallel port

\ Helper function
: ftdi-set  ( value request -- )
   >r >r  0 0  ftdi-port r>   h# 40  r>  control-set drop
;

\ Read internal registers
: ftdi@  ( index -- w )
   >r   ftdi-buf 2   r> 0  h# c0  h# 90  control-get 2drop
   ftdi-buf c@  ftdi-buf 1+ c@  bwjoin
;

\ Various resets
: ftdi-reset     ( -- )  0 0  ftdi-set  ;
: ftdi-flush-rx  ( -- )  0 1  ftdi-set  ;
: ftdi-flush-tx  ( -- )  0 2  ftdi-set  ;

: ftdi-baud  ( baud -- )
   \ There are some high bits for fractional divisors that we don't use
   d# 48000000 swap rounded-/   ( divisor )
   0 swap  3 ftdi-set
;

: ftdi-modem-ctl  ( code -- )  1  ftdi-set  ;
: ftdi-rts-on   ( -- )  h# 202 ftdi-modem-ctl  ;
: ftdi-rts-off  ( -- )  h# 200 ftdi-modem-ctl  ;
: ftdi-dtr-on   ( -- )  h# 101 ftdi-modem-ctl  ;
: ftdi-dtr-off  ( -- )  h# 100 ftdi-modem-ctl  ;

: ftdi-flow-ctl  ( code -- )  2  ftdi-set  ;
: ftdi-flow-none      ( -- )       0 ftdi-flow-ctl  ;
: ftdi-flow-rts-cts   ( -- )  h# 100 ftdi-flow-ctl  ;
: ftdi-flow-dtr-dsr   ( -- )  h# 200 ftdi-flow-ctl  ;
: ftdi-flow-xon-xoff  ( -- )  h# 400 ftdi-flow-ctl  ;

\ h# 800 for 1.5 stop bits, h# 1000 for 2 stop bits
\ h# 300 for mark parity, h# 400 for space parity
: ftdi-data  ( code -- )  4 ftdi-set  ;
: ftdi-8n1  ( -- )      8 ftdi-data  ;
\ : ftdi-8o1  ( -- )  h# 18 ftdi-data  ;
\ : ftdi-8e1  ( -- )  h# 28 ftdi-data  ;
\ : ftdi-7e1  ( -- )  h# 27 ftdi-data  ;
\ : ftdi-7o1  ( -- )  h# 17 ftdi-data  ;

: ftdi-break-on  ( -- )  h# 4000 ftdi-data  ;
\ To send a break, I suppose that you do ftdi-break-on, delay awhile,
\ then ftdi-8n1 or whatever your data format is.

\ Commands that we're unlikely to need
\ : ftdi-set-event-char  ( char -- )  6 ftdi-set  ;
\ : ftdi-set-error-char  ( char -- )  7 ftdi-set  ;
\ : ftdi-set-latency  ( ms -- )  9 ftdi-set  ;

\ CTS: 10  DSR: 20  RI: 40  CD: 80
\ DR: 100  OR: 200  PE: 400  FE: 800  Break: 1000 THRE: 2000 TE: 4000 RXERR: 8000
: ftdi-modem@  ( -- status )
   ftdi-buf 2   ftdi-port 0  h# c0  5  control-get 2drop
   ftdi-buf c@  ftdi-buf 1+ c@  bwjoin
;

\ Data is received on bulk endpoint 1
\ Byte 0 is modem status (CTS - CD as above)
\ Byte 1 is line status (DR - RXERR as above)
\ If there is any real data, it will be returned in bytes 2, ...
\ If there is no data, 2-byte status messages are sent every 40 ms.

\ Data is transmitted on bulk endpoint 2, verbatim.
