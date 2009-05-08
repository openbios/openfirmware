\ Delay N microseconds, N in ax
label usdelay
   cx push

   ax cx mov
   begin  h# 80 # al in  loopa

   cx pop
   ret
end-code
