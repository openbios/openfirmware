: alloc-buffer  ( len -- adr )  " alloc-buffer" $call-parent  ;
: free-buffer  ( adr len -- )  " free-buffer" $call-parent  ;
: cmd-out  ( adr len -- )  " cmd-out" $call-parent  ;
: data-out  ( adr len -- )  " data-out" $call-parent  ;
: got-packet?  ( -- false | error true | buf len type 0 true )  " got-packet?" $call-parent  ;
: recycle-packet  ( -- )  " recycle-packet" $call-parent  ;
: reset-host-bus  ( -- )  " reset-host-bus" $call-parent  ;
: data-out  ( adr len -- )  " data-out" $call-parent  ;
: release-bus-resources  ( -- )  " release-bus-resources" $call-parent  ;
: multifunction?  ( -- flag )  " multifunction?" $call-parent  ;
: set-parent-channel  ( -- )  my-space " set-address" $call-parent  ;
: setup-transport  ( -- error? )  false  ;  \ Done by parent

\ : x-cmd-out  ( adr len -- )  /fw-transport +  cmd-out  ;
