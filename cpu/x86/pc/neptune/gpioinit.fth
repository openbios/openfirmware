purpose: GPIO settings for DAVE Neptune

0 [if] \ This_Is_Documentation
 0    I ~ INTA#
 1 O1     PCBEEP out AUX
 2    I1  IDEIRQ14 in
 3 O      CRT_SCL
 4 O  I   CRT_SDA
 5    I   IDE_CABLEID in
 6    I   GPIO6 out page 26 check (also out from X4 connector pin 42) output from battery monitor header
 7    I ~ INTB# in 10,2025
 8 O 2    O2 IRTX out
 9    I1  IRRX in
10    I1  THRM_ALRM# in
11 O1     SLP_CLK# out would be O1 for SLP_CLK_EN#
12    I ~ INTC# 10,25
13    I ~ INTD#_SLPBUT 25 (I1 for SLPBUT) ??
14 O1 I1  SMB_SCL
15 O1 I1  SMB_SDA

16-20    LPC 21 LPC_SERIRQ 22 LPC_LFRAME

24 O1     WORK_AUX out
25    I1  LOW_BAT# in
26    I   PME# in 18,20,25
27 O1     MFGPT7_C1 out 26
28    I1  pwrbut# in
OutEn - 0900 c91a
OutA1 - 0900 c802
OutA2 - 0000 0100
InEn  - 1600 f6f5
InA1  - 1200 c604
InInv - 0000 3081
[then]
: gpio-init  ( -- )
   h# 0000 h# 1090 pl!  h# c802 h# 1010 pl!  \ Output AUX1
   h# 0000 h# 1094 pl!  h#  100 h# 1014 pl!  \ Output AUX2
   h# 0900 h# 1084 pl!  h# c912 h# 1004 pl!  \ Output Enable
   h# 1600 h# 10a0 pl!  h# f6e5 h# 1020 pl!  \ Input Enable
   h# 1200 h# 10b4 pl!  h# c604 h# 1034 pl!  \ Input AUX1

   h# 0000 h# 10a4 pl!  h# 3081 h# 1024 pl!  \ Input Invert (Int lines)
   h# 0000 h# 10b8 pl!  h# 3081 h# 1038 pl!  \ Event enable (Int lines)

   h# 1000.0000 h# 1098 pl!  \ No pullup on pwrbut_in
   h#      1000 h# 10a8 pl!  \ filter pwrbut_in

   h# 1000.0000 h# 101c pl!  \ No pulldown on INTC#
   h# 3081.cf7e h# 1018 pl!  \ No pullups on INTA..D

   \ h# 0800 h# 1088 pl!  \ MFGPT7_C1 is open drain
   
   \ teo was here
   h# 00000005 h# 10e0 pl!  \ GPIO 0(CaFe) -> group 5
;
