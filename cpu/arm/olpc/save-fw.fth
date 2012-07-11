tag-file @ fclose  tag-file off
my-self [if]
   ." WARNING: my-self is not 0" cr
   bye
[then]

.( --- Saving fw.dic ...)
" fw.dic" $save-forth cr

fload ${BP}/cpu/arm/mmp2/rawboot.fth

.( --- Saving fw.img --- )  cr " fw.img" $save-rom
