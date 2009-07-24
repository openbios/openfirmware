: audio-quiet  ( -- )
   [ ' go-hook behavior compile, ]    \ Chain to old behavior
   audio-ih  if
      audio-ih close-dev
      0 to audio-ih
   then
;
' audio-quiet to go-hook
