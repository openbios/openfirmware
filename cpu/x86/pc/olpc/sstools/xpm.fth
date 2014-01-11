\ save frame buffer in open firmware for screen shots (serial, X bitmap)

dev /display
: fb-va  ( -- fb )  frame-buffer-adr  ;
dend

: .xx  ( b -- )  0 <# # # #>  type  ;

\ colour table,
\ list of unique colours in frame buffer
0 value ct              \ address of table
d# 62 value /ct         \ entries in table (and alphabet utilisation, @-~)
			\ d# 62 is insufficient for menu
h# 0 value nct          \ next entry to use in table

\ borrowed from screen-ih
d# 1200 value width
d# 900 value height
h# 0 value fb-va

: ct-free  ( -- )
   ct /ct /w* free-mem
;

: ct-alloc  ( -- )
   /ct /w* alloc-mem to ct
;

: ct-init  ( -- )
   " fb-va" screen-ih $call-method to fb-va
   ct /ct /w* erase
   h# 0 to nct
;

: ct-dump  ( -- )  \ dump colour table
   nct if
      nct 0 do
         i . ct i wa+ w@ 565>rgb ( r g b ) rot . swap . . cr
      loop
   then
;

: ct-add  ( pixel -- )  \ add a colour to the table if not already in table
   nct if
      nct 0 do                  ( pixel )
         ct i wa+ w@ over = if  ( pixel )       \ found
            drop unloop exit    ( )             \ no action required
         then
      loop                      ( pixel )       \ not found
   then
   nct /ct < if                 ( pixel )
      ct nct wa+ w!             ( )             \ store entry
      nct 1+ to nct             ( )             \ increment next slot
   else
      abort" ct: too many colours in frame buffer"
   then
;

: ct-scan  ( -- )  \ survey what colours are used
   fb-va                        ( fb )
   height 0  do                 ( fb )
      width 0  do               ( fb' )
         dup w@ ct-add 2+       ( fb' )
      loop                      ( fb' )
   loop drop                    ( )
;

: xpm-head  ( -- )
   ." ! XPM2" cr
   width .d height .d
   nct .d 1 .d cr
   nct 0 do
      i h# 40 + emit
      ."  c #"
      ct i wa+ w@ 565>rgb ( r g b ) rot .xx swap .xx .xx cr
   loop
;

: xpm-body  ( -- )
   fb-va                                ( fb )
   height 0  do                         ( fb )
      width 0  do                       ( fb )
         dup w@                         ( fb pixel )
         nct 0 do                       ( fb pixel )
            ct i wa+ w@ over = if       ( fb pixel )       \ found
               i h# 40 + emit           ( fb pixel )
               leave                    ( fb pixel )
            then
         loop                           ( fb pixel )       \ not found
         drop                           ( fb )
         wa1+                           ( fb' )
      loop cr                           ( fb' )
   loop drop                            ( )
;

: .xpm2  \ 256 colour from 16bpp
   ct-alloc
   ct-init
   ct-scan
   xpm-head
   xpm-body
   ct-free
;

: fb-save ( file ( -- )
   to-file .xpm2
;

: ts$  ( -- adr len )
   time&date >unix-seconds push-decimal 0 <# #s #> pop-base
;
