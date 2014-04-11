\ See license at end of file
purpose: OS chooser for dual boot (Android and Linux)

: choice-present?  ( -- present? )
   \ TODO: number of partitions > 2, or specific android files present
   true
;

: choose-os  ( n -- )
   if
      button-o  game-key-mask or  to game-key-mask
   else
      button-o  invert  game-key-mask and  to game-key-mask
   then
;
