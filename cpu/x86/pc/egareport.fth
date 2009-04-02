: v-report  ( char -- )
   " # al mov  al h# b8000 #) mov  h# 1d # al mov  al h# b8001 #) mov" evaluate
;
: vr-report  ( char -- )  \ Real mode version
   " ds push  h# b000 # push ds pop" evaluate   
   " # al mov  al h# 8000 #) mov   h# 1d # al mov  al h# 8001 #) mov"  evaluate
   " ds pop" evaluate
;
