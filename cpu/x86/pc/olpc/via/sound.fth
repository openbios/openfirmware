: close-audio  ( -- )
   audio-ih  if
      audio-ih close-dev
      0 to audio-ih
   then
;
: audio-quiet  ( -- )
   [ ' go-hook behavior compile, ]    \ Chain to old behavior
   close-audio
;
' audio-quiet to go-hook
: xp-wait-audio  ( -- )
   [ ' rm-go-hook behavior compile, ]  \ Chain to old behavior
   sound-end  close-audio
;
' xp-wait-audio to rm-go-hook
