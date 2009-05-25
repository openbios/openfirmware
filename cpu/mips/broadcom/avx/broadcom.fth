purpose: Access to Broadcom spaces
copyright: Copyright 2001 Firmworks  All Rights Reserved

hex
headers

: bcl@  ( idx -- val )  bc-reg-base + l@  ;
: bcl!  ( val idx -- )  bc-reg-base + l!  ;

: bc-cfg@  ( idx -- value )  pci-reg-base + l@  ;
: bc-cfg!  ( value idx -- )  pci-reg-base + l!  ;

