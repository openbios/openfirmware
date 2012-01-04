\ EXT4 extents
d# 12 constant /extent-header
d# 12 constant /extent-record

struct
   /w field >eh_magic
   /w field >eh_entries
   /w field >eh_max
   /w field >eh_depth
   /l field >eh_generation
constant /extent-header

: ext-magic?  ( 'eh -- flag )  >eh_magic short@ h# f30a =  ;
: extent?  ( -- flag )  direct0 ext-magic?  ;

struct
   /l field >ee_block
   /w field >ee_len
   /w field >ee_start_hi
   /l field >ee_start_lo
constant /extent

struct
   /l field >ei_block   \ Same offset and size as >ee_block
   /l field >ei_leaf_lo
   /w field >ei_leaf_hi
   /w +  ( >ei_unused )
constant /extent-index  \ Same length as /extent

: index-block@  ( 'extent-index -- d.block# )
   dup >ei_leaf_lo int@  swap >ei_leaf_hi short@
;
: extent-block@  ( 'extent -- d.block# )
   dup >ee_start_lo int@  swap >ee_start_hi short@
;

: >extent  ( index 'eh -- 'extent )
   /extent-header +  swap /extent *  +
;

\ Works for both extents and extent-index's because they are the
\ same length and their block fields are in the same place.
: ext-binsearch  ( block# 'eh -- block# 'extent )
   >r                       ( block# r: 'eh )
   1                        ( block# left r: 'eh )
   r@ >eh_entries short@ 1- ( block# left right r: 'eh )
   begin  2dup <=  while    ( block# left right r: 'eh )
      2dup + 2/             ( block# left right middle r: 'eh )
      dup r@ >extent        ( block# left right middle 'extent r: 'eh )
      >ei_block int@        ( block# left right middle extent-block r: 'eh )
      4 pick >  if          ( block# left right middle r: 'eh )
         nip 1-             ( block# left right' r: 'eh )
      else                  ( block# left right middle r: 'eh )
         rot drop           ( block# right middle r: 'eh )
         1+ swap            ( block# left' right r: 'eh )
      then                  ( block# left right r: 'eh )
   repeat                   ( block# left right r: 'eh )
   drop  1-                 ( block# left r: 'eh)
   r> >extent               ( block# 'extent )
;

: extent->pblk#  ( logical-block# -- d.physical-block# )
   direct0                      ( logical-block# 'eh )
   dup >eh_depth short@ 0  ?do  ( logical-block# 'eh )
      ext-binsearch             ( logical-block# 'extent-index )
      index-block@              ( logical-block# d.block# )
      d.block                   ( logical-block# 'eh' )

      \ Error check
      dup ext-magic? 0=  if     ( logical-block# 'eh' )
         ." EXT4 bad index block" cr
	 debug-me
      then                      ( logical-block# 'eh' )

   loop                         ( logical-block# 'eh )

   ext-binsearch  >r            ( logical-block# r: 'extent )
   \ At this point the extent should contain the logical block
   r@ >ee_block int@ -          ( block-offset  r: 'extent )
   
   \ Error check
   dup  r@ >ee_len short@  >=  if  ( block-offset  r: 'extent )
      ." EXT4 block not in extent" cr
      debug-me
   then                            ( block-offset  r: 'extent )
   u>d  r> extent-block@  d+       ( d.block# )
;
