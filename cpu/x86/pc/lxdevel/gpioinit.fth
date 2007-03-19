0 [if] \ This_Is_Documentation
 0    I  INTA#
 1 O1    PCBEEP out AUX
 2    I1 IDEIRQ14 in
 3 O     CRT_SCL
 4 O  I  CRT_SDA
 5    I  IDE_CABLEID in
 6    I  GPIO6 out page 26 check (also out from X4 connector pin 42) output from battery monitor header
 7    I  INTB# in 10,2025
 8 O 2   O2 IRTX out
 9    I1 IRRX in
10    I1 THRM_ALRM# in
11 O1    SLP_CLK# out would be O1 for SLP_CLK_EN#
12    I  INTC# 10,25
13    I1 INTD#_SLPBUT 25 (I1 for SLPBUT) ??
14 O1 I1 SMB_SCL
15 O1 I1 SMB_SDA

16-20    LPC 21 LPC_SERIRQ 22 LPC_LFRAME

24 O1    WORK_AUX out
25    I1 LOW_BAT# in
26    I  PME# in 18,20,25
27 O1    MFGPT7_C1 out 26
28    I1 pwrbut# in
OutEn - 0900 c91a
OutA1 - 0900 c802
OutA2 - 0000 0100
InEn  - 1600 f6f5
InA1  - 1200 e604
[then]
: gpio-init  ( -- )
   h# 0900 h# 1090 pl!  h# c802 h# 1010 pl!  \ Output AUX1
   h# 0000 h# 1094 pl!  h# c802 h# 1014 pl!  \ Output AUX2
   h# 0900 h# 1084 pl!  h# c91a h# 1004 pl!  \ Output Enable
   h# 1600 h# 10a0 pl!  h# f6f5 h# 1020 pl!  \ Input Enable
   h# 1200 h# 10b4 pl!  h# e604 h# 1034 pl!  \ Input AUX1
;
