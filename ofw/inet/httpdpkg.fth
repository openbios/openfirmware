\ See license at end of file
purpose: HTTPD Server package

\ To use this code,  be certain that you have an "index.htm"
\ in the ROM as a dropin along with a "homelogo.gif".

hex
headers

\needs httpd-port  d# 80 constant httpd-port

false value httpd-debug?
: ?httpd-show  ( adr len mask -- )
   httpd-debug? and  if  type space  else  2drop  then
;
[ifndef] show"
: ?show  ( adr len -- )  1 ?httpd-show  ;
: show"  ( "str" -- )  postpone " postpone ?show  ; immediate
[then]
[ifndef] state"
: ?state  ( adr len -- )  2 ?httpd-show  ;
: state"  ( "str" -- )  postpone " postpone ?state  ; immediate
[then]
[ifndef] url"
: ?url  ( adr len -- )  4 ?httpd-show  ;
: url"  ( "str" -- )  postpone " postpone ?url  ; immediate
[then]
\needs init-display  : init-display  ( adr len -- )  2drop  ;

true value key-interrupt?
" " 2value pending-cmd

0 value hbuf				\ Accumulator for incoming data
h# 800 constant /hbuf
0 value hbuf-ptr

0 value sbuf				\ A temporary string buffer
h# 40 constant /sbuf

0 value obuf				\ A buffer for constructing headers
h# 800 constant /obuf
0 value obuf-ptr

\ The TCP stack on NT appears to do a better job of collecting data and
\ sending it all at once.  If our receive buffer is too short, then
\ Netscape on NT will choke.  A value of h# 100 will not work here.
0 value thbuf				\ Intermediate buffer to hold data
h# 200 constant /thbuf			\ from TCP stack

: +hptr  ( -- )  hbuf-ptr 1+ to hbuf-ptr  ;
: reset-hbuf-ptr  ( -- )  0 to hbuf-ptr  ;

: hbuf@  ( index -- b )
   hbuf + c@
;

: hbuf-adr  ( --  adr )  hbuf hbuf-ptr +  ;

0 instance value verbose?
0 instance value preprocess?
0 instance value authenticate?

: parse-args  ( -- )
   my-args
   begin  dup  while                                            ( rem$ )
      ascii , left-parse-string                                 ( rem$' head$ )
      2dup " debug"        $=  if  true to httpd-debug?   else  ( rem$' head$ )
      2dup " verbose"      $=  if  true to verbose?       else  ( rem$' head$ )
      2dup " preprocess"   $=  if  true to preprocess?    else  ( rem$' head$ )
      2dup " authenticate" $=  if  true to authenticate?  else  ( rem$' head$ )
      2dup " nokey"        $=  if  false to key-interrupt? else ( rem$' head$ )
      then then then then then                                  ( rem$' head$ )
      2drop
   repeat
   2drop
;

: .ipb  ( adr -- adr' )  dup 1+ swap c@  (.) type   ;
: .ipaddr  ( addr-buff -- )
   push-decimal
   3 0  do  .ipb ." ."  loop  .ipb drop
   pop-base
;

false instance value connected?
: ?bailout  ( -- )
   key-interrupt?  if
      key?  if  key drop  abort  then
   then
   pending-cmd  dup  if
      " " to pending-cmd  include-buffer
   else
      2drop
   then
;
: connect  ( -- )
   httpd-debug?  if  ." Waiting for new connection" cr  then
   state" W"
   begin
      ?bailout
      httpd-port " accept" $call-parent
   until
   true to connected?
   reset-hbuf-ptr	\ Clear the buffer for a new connection
   httpd-debug?  if  ." Connected" cr  then
   state" C"
;

: open  ( -- flag )
   parse-args
   
   " my-ip-addr" $call-parent  collect(	.ipaddr )collect
   2dup init-display
   verbose?  if
      ." http://"
      2dup type
      cr
      key-interrupt?  if
	 ." Type any key to stop." cr
      then
   then
   2drop

   /hbuf alloc-mem to hbuf
   /sbuf alloc-mem to sbuf
   /thbuf alloc-mem to thbuf
   /obuf alloc-mem to obuf
   true
;

\ in-progress? is true while we are collecting and processing a request.
\ It is false while we are polling for a new request on a persistent
\ connection or while there is no open connection.
false value in-progress?

\ This is a special hack that is used by the Swing Solutions application,
\ which has some HTTP requests that do not complete until an exernal event
\ occurs.  The requester can abort the request by dropping the TCP
\ connection, but there are some cases where the TCP drop does not
\ appear to be propagated to the responder.  Executing abort-on-reconnect
\ marks the current TCP connection so that the receipt of a new connection
\ request will abort the current one.
: abort-on-reconnect  ( -- )  " abort-on-reconnect" $call-parent  ;

: reset-connection  ( -- )
   " disconnect" $call-parent
   false to connected?
   false to in-progress?
;

: close  ( -- ) 
   hbuf /hbuf free-mem
   sbuf /sbuf free-mem
   thbuf /thbuf free-mem
   obuf  /obuf free-mem
;

: read   ( adr len -- actual )
   " read" $call-parent   dup -1 =  if
      connected?  if  show" HDROP"  then
      false to connected?
   then
;
: write   ( adr len -- actual )  " write" $call-parent ;

: match?  ( match$ -- match? )  hbuf over $=  ;

: (send-all)  ( adr len -- )
   dup 0=  if  2drop exit  then
   tuck  write 2dup <>  if      ( len actual )
      dup -1 =  if
         ." Connection closed prematurely" cr
	 show" HSDROP"
      else
	 ." Write failure" cr
	 show" HWERR"
      then
   then
   2drop
;
defer send-all  ' (send-all) to send-all

: >obuf  ( adr len -- )
   tuck  obuf-ptr swap move   obuf-ptr + to obuf-ptr
;
: init-obuf  ( -- )
   ['] >obuf to send-all
   obuf to obuf-ptr
;
: send-obuf  ( -- )
   ['] (send-all) to send-all
   obuf  obuf-ptr over -  send-all
;

: send-crlf  ( -- )  " "r"n" send-all  ;

: num>ascii  ( n -- $ )  (u.)  ;

\ A vrsion of cat that re-uses the same buffer, rather that continually
\ using alloc-mem to create a new string.
: $cat2  ( $1 $2 -- $3 )
   \ First figure final length
   2 pick over + >r			( $1 $2 ) ( r: 3len )

   \ Move the first string to buffer, saving length
   2swap dup >r sbuf swap move r>	( $2 len ) ( r: 3len )

   \ Now move second string
   sbuf + swap move			( ) ( r: len )

   \ Now go..
   sbuf r>				( $3 )
;

: create-num$  ( len -- num$ )  push-decimal num>ascii pop-base  ;

: get-type  ( adr len -- c )
   0 -rot
   bounds do
      i c@ [char] . =  if  drop i  then 	( adr )
   loop
   1+ c@
;

: send-content-type  ( type$ -- )
   " Content-Type: " 2swap  $cat2	( adr len )
   " "r"n" $cat2			( adr len' )
   httpd-debug?  if  2dup type  then	( adr len' )
   send-all
;
: presume-content-type  ( url$ -- type$ )
   get-type upc			( type-char )
   case
      ascii H  of  " text/html"  endof
      ascii B  of  " image/bmp"  endof
      ascii G  of  " image/gif"  endof
      ascii J  of  " image/jpeg" endof
      ( default )  >r  " text/html"  r>
   endcase
;

: send-agent  ( -- )  " User-Agent: FirmWorks/1.0"r"n"    send-all  ;
: 200-header  ( -- )  " HTTP/1.0 200 OK"r"n"              send-all  ;
: 202-header  ( -- )  " HTTP/1.0 202 Accepted"r"n"        send-all  ;
: 204-header  ( -- )  " HTTP/1.0 204 No Content"r"n"      send-all  ;
: 401-header  ( -- )  " HTTP/1.0 401 Not Authorized"r"n"  send-all  ;
: 404-header  ( -- )  " HTTP/1.0 404 Not Found"r"n"       send-all  ;

defer send-header
['] 200-header to send-header

false value persistent?		\ False means to disconnect after xfers

: send-connection  ( -- )
   persistent?  if		\ HTTP 1.1 needs to be persistent
      " Connection: Keep-Alive"r"n"	( adr len )
      httpd-debug?  if  2dup type  then	( adr len )
      send-all				( )
   then
;

: count-content  ( data$ .. n -- data$ .. n len )
   0 over 0  ?do           ( data$ .. n len )
      i 2* 2+ pick +       ( data$ .. n len' )
   loop
;
: send-content-length  ( data$ .. n -- data$ .. n )
   count-content                        ( data$ .. n len )
   " Content-Length: "			( data$ .. n len adr len )
   rot create-num$ $cat2		( data$ .. n adr len' )
   " "r"n" $cat2			( data$ .. n adr len'' )
   httpd-debug?  if  2dup type  then	( data$ .. n adr len'' )
   send-all				( data$ .. n )
;

: send-pieces  ( data$ .. n -- )
   0  ?do  send-all  loop
;   

: type-cr  ( adr len -- )  type cr  ;

\ full-response is what is used to respond to HTTP 1.0 or higher requests.
: full-response  ( data$ .. n type$ -- )
   httpd-debug?  if  ." Sending: "  2dup type-cr  then
   init-obuf
   send-header			 ( data$ .. n type$ )
   send-agent	 	         ( data$ .. n type$ )
   send-connection		 ( data$ .. n type$ )
   send-content-type		 ( data$ .. n )
   send-content-length	         ( data$ .. n )
   send-crlf			 ( data$ .. n ) \ Data separator
   send-obuf
   send-pieces                   ( )		\ Send all segments of the data
;

\ simple-response is used to respond to HTTP 0.9 requests
: simple-response  ( data$ .. n type$ -- )  2drop send-pieces  ;

: send-response-header  ( data$ .. n header$ -- )
   httpd-debug?  if  ." Sending: "  2dup type-cr  then
   init-obuf
   send-header			( data$ .. n header$ )
   send-all			( data$ .. n )
   send-crlf			( data$ .. n ) \ Data separator
   send-obuf
   send-pieces                  ( )		\ Send all segments of the data
;

defer (send)
['] full-response to (send)	\ Default to HTTP 1.0 full-responses for now

: respond  ( data$ .. n type$ -- )
   state" R"
   connected? 0=  if               ( data$ .. n type$ )
      httpd-debug?  if  ." Discarding response to aborted connection"  cr  then
      2drop  0 ?do  2drop  loop 
      exit
   then 
   (send)
   state" S"
;

\ Send a block of preformatted data
: send-html  ( adr len -- )  1  " text/html"  respond  ;

: hbuf@++  ( -- char )  hbuf-ptr hbuf@  +hptr  ;
: skip-til-white  ( -- )   begin   hbuf@++  bl =  until  ;
: skip-til  ( char -- )  begin   dup  hbuf@++  =  until  drop  ;
: skip-til-crlf  ( -- )  carret skip-til +hptr  ;

: skip-til-white-or-?  ( -- )
   begin   hbuf@++  dup  bl =  swap  [char] ? =  or  until
;

: extract-url  ( -- option$ url$ )	\ Pull URL $ from incomming request
   reset-hbuf-ptr		( ) 
   skip-til-white		( )
   hbuf-adr			( start-adr )
   skip-til-white-or-?		( start-adr )
   hbuf-adr over - 1-		( start-adr len )

   \ Kill off leading "/" from return
   dup 1 >= if  over c@  [char] / =  if  1 /string  then  then

   dup 0=  if			( url$ )        \ But is it real?
      2drop  0 0		( 0 0 )
      " index.htm"		( 0 0 url$ )	\ Our default
      exit			( 0 0 url$ )	\ Get out of dodge...
   then	

   hbuf-ptr 1- hbuf@ ascii ? =  if			\ We have options...
      hbuf-adr			( url$ opt-adr )
      skip-til-white		( url$ opt-adr )
      hbuf-adr over - 1-	( url$ opt-adr opt-len )
      2swap			( opt$ url$ )
   else
      0 0 2swap			( 0 0 url$ )	\ No options
   then
;

\ Dump preformatted tag into output stream
: create-pre  ( -- )  " <PRE>" type-cr  ;

\ Dump end-preformatted tag into output stream
: create-endpre  ( -- )  " </PRE>" type-cr  ;

\ Dump a basic HTML header into output stream
: create-header  ( -- )
   no-page
   " <HTML>" type-cr
   " <HEAD>" type-cr
   " <TITLE>Internet ROM</TITLE>" type-cr
   " </HEAD>" type-cr
   " <BODY TEXT=""#000000"" BGCOLOR=""#FFFFFF"" LINK=""#0000FF"" " type-cr
   " VLINK=""#FF4400"">" type-cr
   " <hr>" type-cr
;

\ Dump a link to home into output stream
: et-go-home  ( -- )
   " <CENTER><A href=""index.htm"" target=""_top"">Back to Main Page</A></CENTER>" type-cr
;

\ Dump a footer into the output stream
: create-footer  ( -- )
   " <br>" type-cr
   et-go-home
   " <hr>" type-cr
   " <CENTER><IMG SRC=""homelogo.gif""></CENTER>" type-cr
   " </BODY>" type-cr
   " </HTML>" type-cr
   page-mode
;

\ Collect output from execute ROM command
: collect-data  ( xt -- adr len )
   collect(				( xt )
      create-header			( xt )
      create-pre			( xt )
      guarded				( )
      create-endpre			( )
      create-footer			( )
   )collect				( adr len )
;

\needs auth-header  : auth-header  ( -- $ )  " WWW-Authenticate: Basic realm=""OFW"""n"r"  ;

: send-204  ( -- )
   httpd-debug?  if  ." Sending 204" cr  then
   ['] 200-header to send-header
   ['] banner collect-data  send-html
   ['] 200-header to send-header
;

: send-401  ( -- )
   httpd-debug?  if  ." Sending 401" cr  then
   ['] 401-header to send-header
   ['] send-response-header to (send)
   0 auth-header respond
   ['] 200-header to send-header
;

: send-404  ( -- )
   httpd-debug?  if  ." Sending 404" cr  then
   ['] 404-header to send-header
   " The ROM cannot supply this information."  send-html
   ['] 200-header to send-header
;

\ HTML preprocessing before sending to browser.

0 0 instance 2value rem$
0 instance value #data$
: #data$+  ( -- )  #data$ 1+ to #data$  ;
: find$  ( s$ t$ -- offset find? )
   2>r	 			( s$ )  ( R: t$ )
   0 -rot  begin		( offset s$ )  ( R: t$ )
      over 2r@ comp 0=  if  2r> 2drop 2drop true exit  then
      1 /string			( offset s$' )  ( R: t$ )
      rot 1+ -rot		( offset' s$ )  ( R: t$ )
   dup 0=  until  2r> 2drop 2drop false	( offset )
;
: eval-forth  ( -- data$ ... )
   rem$ 7 /string 2dup to rem$		( adr len )
   " </FORTH>" find$ 0=  if  ." Missing </FORTH>" abort  then	( offset )
   rem$ drop swap			( forth$ )
   rem$ 2 pick 8 + /string to rem$	( forth$ )
   evaluate				( data$ ... n )
   #data$ + to #data$			( data$ ... )
;
: swap-data$  ( data$ ... -- data$' ... n )
   #data$  if
      #data$  begin
         dup 2* pick  over 2* pick 2>r
         1- ?dup 0=
      until
      #data$ 0  do  2drop  loop
      #data$  begin
         2r> rot 1- ?dup 0=
      until
   then  #data$
;
: (preprocess-html)  ( data$ -- data$' ... n )
   to rem$
   begin
      rem$ " <FORTH>" find$ over 	( offset found? offset )
      #data$+
      rem$ drop swap 2>r		( offset found? )  ( R: data$ )
      swap rem$ rot /string to rem$ 2r>	( found? data$ )
      rot  if  eval-forth  then		( data$ ... )
      rem$ nip 0=
   until
   swap-data$				( data$ ... n )
;
: preprocess-html  ( url$ data$ -- data$' ... n' )
   preprocess?  if			( url$ data$ )
      0 to #data$			( url$ data$ )
      2swap get-type upc ascii H =  if	( data$ )
         (preprocess-html)		( data$' ... n )
      else				( data$ )
         1				( data$ n )
      then
   else					( url$ data$ )
      2swap 2drop 1			( data$ n )
   then
;

: transaction-done  ( -- )
   state" T"
   persistent?  if
      url" tdonefw"
      " flush-writes" $call-parent
      reset-hbuf-ptr
      false to in-progress?
   else
      \ url" tdonerc"
      reset-connection
   then
   state" D"
;

[ifndef] urls
also forth definitions
vocabulary urls
previous definitions
[then]

: handle-url  ( opt$ url$ -- )
   2dup ['] urls search-wordlist  if   ( opt$ url$ xt )
      execute                          ( data$ .. n type$ )
      respond			       ( )
      state" H"
      exit                             ( )
   then                                ( opt$ url$ )

   2dup find-drop-in  if               ( opt$ url$ data$ )
      2over 2>r			       ( opt$ url$ data$ )  ( R: url$ )
      2>r 2>r 2drop 2r> 2r>	       ( url$ data$ )  ( R: url$ )
      preprocess-html		       ( data$' n )  ( R: url$ )
      2r> presume-content-type         ( data$ n type$ )
      respond                          ( )
      exit                             ( )
   then                                ( opt$ url$ )

   4drop  send-404                     ( )
;

\ Basic HTTP strings all end with "crlf"
: dual-crlf?  ( adr -- flag )  4 - hbuf +  " "(0d0a0d0a)" comp 0=  ;

: request-complete?  ( -- complete? )	\ Tells us if we have all were going
					\ to get.
   \ HTTP 0.9 looks like:
   \   GET <url> crlf

   \ HTTP 1.0/1.1 looks like:
   \   GET <url> HTTP/1.0 crlf ...<a bunch of crlf terminated crud>... crlf

   \ The major difference being that 0.9 is a single line with a single
   \ crlf at the end, 1.0 (and higher ) is multi-line (each line terminated
   \ by crlf) with an additional crlf at the end of the request.

   \ We need to determine which one we have in the buffer, and if complete,
   \ return true so that the request can be processed.  We also want to set
   \ the response type up here to simple or full depending on 0.9 or 1.x

   hbuf-ptr		       ( ptr )	 \ Save for later

   \ Reset the pointer, then advance it to where HTTP would be if we
   \ have HTTP 1.0 request.

   reset-hbuf-ptr	       ( ptr )
   skip-til-white	       ( ptr )
   skip-til-white	       ( ptr )

   \ Now test the buffer and take action accordingly

   " HTTP"  hbuf hbuf-ptr + 4  ( ptr test$ buf$ )
   $=  if		       ( ptr )	   \ HTTP 1.x
      ['] full-response to (send)
      \ Now we have to see if we have all of this request or not
      dup dual-crlf?	       ( ptr flag )

      \ Now we have to setup to deal with persistent connections.
      \ This is a bit of a cheat.  We should be looking at the
      \ "connection:" field (if it exists) in the incoming URL
      \ requset.  If it set to "Keep-Alive" then we would set
      \ the persistent flag.  But so far, *everyone* always sets
      \ the Keep-Alive flag.  But 1.0 implementations don't work,
      \ and 1.1 implementations really want it to.  So we just
      \ set the persistance based on 1.1ness.
      
      \ " 1.0"  hbuf hbuf-ptr + 5 +  3  $=  0=  to persistent?
   else					   \ HTTP 0.9
      \ We have all we are going to get.
      ['] simple-response to (send)
      true		       ( ptr true )
   then

   swap to hbuf-ptr	       ( flag )	   \ Restore buffer pointer in case
					   \ there is more to come.
;

: b64>6bit  ( byte -- 6bit )
   dup ascii A ascii Z between  if  ascii A -  exit  then
   dup ascii a ascii z between  if  ascii a - d# 26 +  exit  then
   dup ascii 0 ascii 9 between  if  ascii 0 - d# 52 +  exit  then
   case
      ascii +  of  3e  endof
      ascii /  of  3f  endof
      ( default )  0 swap
   endcase
;

: b64>ascii  ( b64$ -- adr len )
   over dup >r 0 2swap			( adr len b64$ )  ( R: adr )
   bounds  ?do				( adr len )  ( R: adr )
      i l@ lbsplit			( adr len b3 b2 b1 b0 )  ( R: adr )
      b64>6bit d# 18 <<			( adr len b3 b2 b1 val )  ( R: adr )
      swap b64>6bit d# 12 << or		( adr len b3 b2 val' )  ( R: adr )
      swap b64>6bit d# 6 << or 		( adr len b3 val' )  ( R: adr )
      swap b64>6bit or			( adr len val' )  ( R: adr )
      lbsplit drop			( adr len b3 b2 b1 )  ( R: adr )
      4 pick c!				( adr len b3 b2 )  ( R: adr )
      3 pick 1+ c!			( adr len b3 )  ( R: adr )
      2 pick 2 + c!			( adr len )  ( R: adr )
      3 + swap 3 + swap			( adr' len' )  ( R: adr )
   4 +loop
   dup  if				\ strip trailing 0's
      3 1  do
         over i - c@ 0=  if  1-  then
      loop
   then  nip				( len' )
   r> swap				( adr len )
;

: (authorized?)  ( realm$ pwd$ user$ -- authorized? )
   " admin" $= >r " ofw" $= r> and
   -rot 2drop
;

defer authorized?
[ifdef] oem-authorized?
   ['] oem-authorized? to authorized?
[else]
   ['] (authorized?) to authorized?
[then]

: extract-auth  ( -- realm$ pwd$ user$ )
   begin  skip-til-crlf hbuf-adr " "(0d0a)" comp  while
      hbuf-adr				( adr )
      [char] : skip-til			( adr )
      hbuf-adr over - 1-		( token$ )
      " Authorization" $=  if		( )
         skip-til-white			( )
         hbuf-adr			( adr )
	 skip-til-white
         hbuf-adr over - 1-		( realm$ )
	 hbuf-adr			( realm$ adr )
         skip-til-crlf
         hbuf-adr over - 2 -		( realm$ base64$ )
         b64>ascii			( realm$ user:pwd$ )
         [char] : left-parse-string     ( realm$ pwd$ user$ )
	 exit
      then
   repeat
   null$ null$ null$
;

: authenticate-request?  ( -- authorized? )
   extract-auth			( realm$ pwd$ user$ )
   authorized?
;

\ Since we serve up the HTML code, we can decide what to support. You
\ can do everything with "GET"s, and do not really need to support
\ POSTs.  POSTs are better for security issues, but since this code
\ would not really be executed in the normal case, this should be a
\ minor issue.

: do-get  ( -- )
   request-complete?  if

      httpd-debug?  if  cr hbuf hbuf-ptr type  then

      extract-url			( opt$ url$ )

      httpd-debug?  if			( opt$ url$ )
         ." URL: " 2dup type-cr		( opt$ url$ )
         2over				( opt$ url$ opt$ )
         ?dup  if			( opt$ url$ opt$ )
            ." OPT: " type-cr		( opt$ url$ )
         else  drop  then		( opt$ url$ )
      then				( opt$ url$ )

      authenticate?  if			( opt$ url$ )
         authenticate-request? 0=  if	( )
	    4drop			( )
            send-401
            transaction-done
            exit
         then
      then

      handle-url                	( )

      transaction-done
   then
;

: do-post  ( -- )
   request-complete?  if
      httpd-debug?  if  cr hbuf hbuf-ptr type  then
      send-204
      transaction-done
   then
;

: handle-buf  ( -- )
   " GET" match?  if  do-get  then
   " POST" match?  if  do-post  then
;

false instance value crlf-seen?
: >hbuf  ( b -- )    \ Accumulate data, when we get a CRLF pair, go check it
   hbuf hbuf-ptr + c!
   +hptr
   hbuf-ptr 2 >=  if
      hbuf-ptr hbuf + 2- " "(0d0a)"  comp 0=  if  handle-buf  then
   then
;

0 value end-time
d# 5000 constant short-time
d# 30000 constant long-time

: reset-timer  ( -- )
   true to in-progress?
   persistent?  if  long-time  else  short-time  then  ( timeout-msecs )
   get-msecs +  to end-time
;

: do-disconnect  ( -- )
   httpd-debug?  if  ." Disconnect reset" cr  then
   url" discrc"
   reset-connection
;
: do-idle  ( -- )
   in-progress?  if
      key-interrupt?  if
         key?  if
            key drop
            ." HTTPD transaction in progress; interacting " cr
            interact
         then
      then
   else
      ?bailout
   then

   persistent?  if  exit  then
   get-msecs end-time -  0>  if
      httpd-debug?  if  ." Timeout reset" cr  then
      url" idlerc"
      reset-connection
   then
;

\ Call into the TCP stack, just shovel the data to our collection
\ buffer.  The shoveler (>hbuf) will decide when there is enough
\ data to work on.
: httpd-loop  ( -- )
   false to in-progress?
   begin
      connected?  0=  if  connect reset-timer  then
 
      thbuf /thbuf read  case	( -1|-2|actual )
         -1  of  do-disconnect  endof
         -2  of  do-idle        endof
         ( actual )
            reset-timer				     ( actual )
            thbuf over bounds  do  i c@ >hbuf  loop  ( actual )
       endcase
       key-interrupt? if  key?  if  key emit exit  then  then
   again
;


\ builtin URLs
\ this is essentially demo code

hex
headers

\ support for the built-in URLs

\ Creates return message for setenv
: nice-message  ( val$ var$ -- adr len )
   collect(					( val$ var$ )
      create-header				( val$ var$ )
      " ROM Configuration Variable " type	( val$ var$ )
      " <b>" type				( val$ var$ )
      type		  			( val$ )
      " </b>" type				( val$ )
      "  set to " type				( val$ )
      " <b>" type				( val$ )
      type-cr					( )
      " </b>" type				( )
      " <br> <br>" type-cr
      create-footer
   )collect
;

\ \ Creates return message for setenv
\ : nice-message1  ( var$ -- adr len )
\    collect(					( var$ )
\       create-header				( var$ )
\       " ROM Configuration Variable " type	( var$ )
\       " <b>" type				( var$ )
\       type		  			( )
\       " </b>" type				( )
\       "  set to default value" type		( )
\       " </b>" type				( )
\       " <br> <br>" type-cr
\       create-footer
\    )collect
\ ;

\ HTTP strings have a "+" where blanks are suppsed to be.  Just whack them.
: fix-blanks  ( adr len -- )
   bounds  ?do
      i c@  [char] + =  if  bl i c!  then
   loop
;

\ HTTP strings mungle up the special characters.  Instead of a "/" for
\ example, you get "%2F".  This routine looks for the "%" characters,
\ extracts the ascii string after that, converts it to the real hex
\ value and punches it back where the "%" was, then moves everything
\ else to the left by two.
: fixup-string  ( adr len -- adr len' )
   2dup fix-blanks		 \ First whack the blanks into shape.
   dup 3 <  if  exit  then	 \ Cannot possibly have %xx.
   2dup 2- bounds  ?do
      i c@ [char] % =  if
         i 1+ 2  $number  0<>  if  ." Parsing error"  unloop exit then
         ( adr len b ) i c!
         i 3 +			( adr len src )
         i 1 +			( adr len src dst )
         over  4 pick - 	( adr len src dst #ok )
         3 pick swap -		( adr len src dst len )
         move			( adr len )
         2-			( adr len' )
      then
   loop
;

also urls definitions

: stop  ( opt$ url$ -- httpd-stuff )
   " abort" to pending-cmd
   " Closing remote HTTP server" 1 " text/plain"
;
: reboot  ( opt$ url$ -- httpd-stuff )
   " bye" to pending-cmd
   " Rebooting remote system" 1 " text/plain"
;

\ This is really demo code, not ready for primetime.  We deal with some
\ special cases with this code example.  If a URL comes in as
\ "rom-setconfig-tf", then we go look for some other stuff in the
\ incomming request packet, reformat the whole wad into a "setenv"
\ command and execute it.  This "-tf" method looks at the first
\ character of the incoming set string for "t" or "f" and then creates
\ its own "true" or "false" to pass to the setenv command.  Helps with
\ people that can't spell.  The second special is really a more general
\ case inplementaion.  rom-setconfig-string parses out the string that
\ is passed in and sets the environment variable accordingly.  Just
\ another way to do it.  Demo code after all.  If the request URL has
\ "rom-ok" in it, we treat the passed in data as a string that we just
\ pass to the "ok" prompt, returning whatever we get back.  Any other
\ request that is prefeaced by "rom-" is assumed to be a method call, so
\ we go look for an XT, then execute it, returning the data.  Thus
\ showing four possibilities of how one might interface to the ROM via
\ HTTP.

: rom-setconfig-tf  ( opt$ url$ -- httpd-stuff )
   \ OK, the option string will have what we need in it.  We need to
   \ extract what we need from it, run the setenv command and return
   \ something nice to the user...
   2drop
   hbuf swap move			( ) \ Re-use the hbuf  XXX this is bad.
   reset-hbuf-ptr
   [char] = skip-til hbuf-adr		( adr )
   [char] & skip-til hbuf-adr over - 1-	( var$ )
   fixup-string				( var$' )
   [char] = skip-til			( var$' adr )
   hbuf-adr c@ ascii t =  if  
      " true"  else  " false"		( var$' val$ )
   then
   2swap  4dup				( val$ var$' val$ var$' )
   collect( $setenv )collect	        ( val$ var$' adr len )
   2drop				( val$ var$' )
   nice-message 1 " text/html"
;

: rom-setconfig-string  ( opt$ url$ -- httpd-stuff )
   \ OK, the option string will have what we need in it.  We need to
   \ extract what we need from it, run the setenv command and return
   \ something nice to the user...
   2drop
   hbuf swap dup >r move		( ) \ Re-use the hbuf
   reset-hbuf-ptr
   [char] = skip-til hbuf-adr		( adr )
   [char] & skip-til hbuf-adr over - 1-	( var$ )
   fixup-string				( var$' )
   [char] = skip-til			( var$' )
   hbuf-adr				( var$ val-adr )
   hbuf -				( var$ count )
   hbuf r>				( var$ count adr len )
   rot /string				( var$ val$ )
   fixup-string				( var$ val$ )
   2swap 4dup				( val$ var$' val$ var$' )
   collect( $setenv )collect	        ( val$ var$' adr len )
   2drop				( val$ var$' )
   nice-message   1 " text/html"
;

: rom-setdefault  ( opt$ url$ -- httpd-stuff )
   \ OK, the option string will have what we need in it.  We need to
   \ extract what we need from it, run the set-default command and return
   \ something nice to the user...
   2drop
   hbuf swap dup >r move		( ) \ Re-use the hbuf
   reset-hbuf-ptr
   [char] = skip-til hbuf-adr		( adr )
   hbuf -  hbuf r> rot /string		( var$ )
   fixup-string 2dup			( var$' var$' )
   collect(
      create-header
      create-pre
      find-option  if  do-set-default  then
      (printenv)
      create-endpre
      create-footer
   )collect				( adr len )
   1 " text/html"
;

: rom-restart  ( opt$ url$ -- )
   \ rom-restart?option_file=url&var=value
   2drop
   hbuf swap dup >r move		( ) \ Re-use the hbuf
   reset-hbuf-ptr
   [char] = skip-til hbuf-adr		( adr )
   [char] & skip-til hbuf-adr over - 1-	( url$ )
   fixup-string				( url$' )

   2dup find-drop-in  if      		( url$ data$ )
      2over 2>r				( url$ data$ )  ( R: url$ )
      preprocess-html			( data$' n )
      2r> presume-content-type		( data$ n type$ )
      respond				( )
      transaction-done			( )
   else					( url$ )
      2drop
   then

   hbuf-adr [char] = skip-til		( var )
   hbuf-adr over - 1-			( var$ )

   hbuf-adr				( var$ val-adr )
   hbuf -				( var$ count )
   hbuf r>				( var$ count adr len )
   rot /string				( var$ val$ )
   fixup-string 2swap			( val$' var$ )
   collect( $setenv )collect 2drop	( )

   reset-all
;

\ command?here+.+cr		plusses become blanks
\ command?4+5+%2b+.+cr		use %2b to get a plus
\ note: the web page encodes the command string before sending it
\  and sends command?command=here+.+cr
: cmdeq  ( -- $ )   " command="  ;
: command   ( opt$ url$ -- httpd-stuff )
   2drop
   cmdeq 2over sindex 0= if
      cmdeq nip /string
   then
   fixup-string  ['] eval collect-data  1 " text/html"
;

previous definitions
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
