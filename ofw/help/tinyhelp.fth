purpose: Rudimentary help facility

: help  ( "topic" -- )
   postpone \
   ." go                       - Resume execution of OS" cr
   ." boot                     - Boot the default OS" cr
   ." boot <device-name>       - Boot from the specified disk" cr
   ." printenv                 - Display all configuration variables" cr
   ." setenv <name> <value>    - Set a configuration variable" cr
   ." devalias                 - Display all device aliases" cr
   ." devalias <name> <value>  - Create or change a device alias" cr
   ." show-devs                - Display the names of all devices" cr
   cr
   ." Many other commands are available." cr
;
