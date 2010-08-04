\ This is a workaround for a reset problem with the Marvell 88W8686
\ as described in Marvell AppNote AN-20017.  Basically, you have to
\ pulse the external reset pin after powering up the module, otherwise
\ it might not reset correctly.

: mv8686-reset-quirk  ( -- )
   d# 50 ms
   " wlan-reset" evaluate
;
' mv8686-reset-quirk to ?mv8686-quirk
