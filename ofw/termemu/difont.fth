purpose: Incorporate font into dictionary from dropin module

0 value 'di-font

: di-font  ( -- adr )
   'di-font ?dup  if  exit  then
   " font" find-drop-in  if  drop to 'di-font  'di-font  exit  then
   0
;
' di-font to romfont
