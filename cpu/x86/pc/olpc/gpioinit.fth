: gpio-init
\  h# f7ff0800 h# 1000 pl!  \ GPIOL_OUTPUT_VALUE 
\  h# 36ffc900 h# 1004 pl!  \ GPIOL_OUTPUT_ENABLE 
   h#     d802 h# 1004 pl!  \ GPIOL_OUTPUT_ENABLE - SMI#, DCONLOAD, MIC
\  h# ffff0000 h# 1008 pl!  \ GPIOL_OUT_OPENDRAIN - default
\  h# ffff0000 h# 100c pl!  \ GPIOL_OUTPUT_INVERT_ENABLE - default
   h#     c000 h# 1010 pl!  \ GPIOL_OUT_AUX1_SELECT - enable SMBUS pins
\  h# ffff0000 h# 1014 pl!  \ GPIOL_OUT_AUX2_SELECT - default
\  h# 1001effe h# 1018 pl!  \ GPIOL_PULLUP_ENABLE - I don't think we need pullups
   h# 02080000 h# 1018 pl!  \ GPIOL_PULLUP_ENABLE - Disable pullups except for UART Rx
\  h# efff1000 h# 101c pl!  \ GPIOL_PULLDOWN_ENABLE - default
   h# ffff0000 h# 101c pl!  \ GPIOL_PULLDOWN_ENABLE - Disable all pull-downs
   h#     d6e5 h# 1020 pl!  \ GPIOL_INPUT_ENABLE - DCONBLNK, DCONLOAD, THERM_ALRM, DCONIRQ, DCONSTAT1/0, MEMSIZE, PCI_INTA
   h#     0081 h# 1024 pl!  \ GPIOL_INPUT_INVERT_ENABLE - Invert DCONIRQ and PCI_INTA#
\  h# ffff0000 h# 1028 pl!  \ GPIOL_IN_FILTER_ENABLE - default
\  h# ffff0000 h# 102c pl!  \ GPIOL_IN_EVENTCOUNT_ENABLE - default
\  h# 2d9bd264 h# 1030 pl!  \ GPIOL_READ_BACK
   h#     c600 h# 1034 pl!  \ GPIOL_IN_AUX1_SELECT
   h#     0081 h# 1038 pl!  \ GPIOL_EVENTS_ENABLE 
\  h# 00000000 h# 103c pl!  \ GPIOL_LOCK_ENABLE - default
\  h# ffff0000 h# 1040 pl!  \ GPIOL_IN_POSEDGE_ENABLE - default
\  h# ffff0000 h# 1044 pl!  \ GPIOL_IN_NEGEDGE_ENABLE - default
\  h# 0000ffff h# 1048 pl!  \ GPIOL_IN_POSEDGE_STATUS - R/WC
\  h# 0000ffff h# 104c pl!  \ GPIOL_IN_NEGEDGE_STATUS - R/WC
\  h#     0000 h# 1050 pw!  \ GPIO_00_FILTER_AMOUNT - default
\  h#     0000 h# 1052 pw!  \ GPIO_00_FILTER_COUNT - default
\  h#     0000 h# 1054 pw!  \ GPIO_00_EVENT_COUNT - default
\  h#     0000 h# 1056 pw!  \ GPIO_00_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 1058 pw!  \ GPIO_01_FILTER_AMOUNT - default
\  h#     0000 h# 105a pw!  \ GPIO_01_FILTER_COUNT - default
\  h#     0000 h# 105c pw!  \ GPIO_01_EVENT_COUNT - default
\  h#     0000 h# 105e pw!  \ GPIO_01_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 1060 pw!  \ GPIO_02_FILTER_AMOUNT - default
\  h#     0000 h# 1062 pw!  \ GPIO_02_FILTER_COUNT - default
\  h#     0000 h# 1064 pw!  \ GPIO_02_EVENT_COUNT - default
\  h#     0000 h# 1066 pw!  \ GPIO_02_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 1068 pw!  \ GPIO_03_FILTER_AMOUNT - default
\  h#     0000 h# 106a pw!  \ GPIO_03_FILTER_COUNT - default
\  h#     0000 h# 106c pw!  \ GPIO_03_EVENT_COUNT - default
\  h#     0000 h# 106e pw!  \ GPIO_03_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 1070 pw!  \ GPIO_04_FILTER_AMOUNT - default
\  h#     0000 h# 1072 pw!  \ GPIO_04_FILTER_COUNT - default
\  h#     0000 h# 1074 pw!  \ GPIO_04_EVENT_COUNT - default
\  h#     0000 h# 1076 pw!  \ GPIO_04_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 1078 pw!  \ GPIO_05_FILTER_AMOUNT - default
\  h#     0000 h# 107a pw!  \ GPIO_05_FILTER_COUNT - default
\  h#     0000 h# 107c pw!  \ GPIO_05_EVENT_COUNT - default
\  h#     0000 h# 107e pw!  \ GPIO_05_EVENTCOMPARE_VALUE - default

   h#     0100 h# 1090 pl!  \ GPIOH_OUT_AUX1_SELECT - GPIO24 is WORK_AUX
   h#     0100 h# 1084 pl!  \ GPIOH_OUTPUT_ENABLE - GPIO24 is WORK_AUX

\  h# ffff0000 h# 1080 pl!  \ GPIOH_OUTPUT_VALUE - default
\  h# ffff0000 h# 1084 pl!  \ GPIOH_OUTPUT_ENABLE - default
\  h# ffff0000 h# 1088 pl!  \ GPIOH_OUT_OPENDRAIN - default
\  h# ffff0000 h# 108c pl!  \ GPIOH_OUTPUT_INVERT_ENABLE - default
\  h# ffff0000 h# 1094 pl!  \ GPIOH_OUT_AUX2_SELECT - default
\  h# 0000ffff h# 1098 pl!  \ GPIOH_PULLUP_ENABLE - default
\  h# ffff0000 h# 109c pl!  \ GPIOH_PULLDOWN_ENABLE - default
\  h# efff1000 h# 10a0 pl!  \ GPIOH_INPUT_ENABLE - default
   h#     1c00 h# 10a0 pl!  \ GPIOH_INPUT_ENABLE - PWR_BUT#, SCI#, PWR_BUT_in
\  h# ffff0000 h# 10a4 pl!  \ GPIOH_INPUT_INVERT_ENABLE - default
\  h# ffff0000 h# 10a8 pl!  \ GPIOH_IN_FILTER_ENABLE - default
\  h# ffff0000 h# 10ac pl!  \ GPIOH_IN_EVENTCOUNT_ENABLE - default
\  h# efff1000 h# 10b0 pl!  \ GPIOH_READ_BACK
\  h# efff1000 h# 10b4 pl!  \ GPIOH_IN_AUX1_SELECT - default
\  h# ffff0000 h# 10b8 pl!  \ GPIOH_EVENTS_ENABLE - default
   h#     0c00 h# 10b8 pl!  \ GPIOH_EVENTS_ENABLE - SCI#, PWR_BUT_in
\  h# 00000000 h# 10bc pl!  \ GPIOL_LOCK_ENABLE - default
\  h# ffff0000 h# 10c0 pl!  \ GPIOH_IN_POSEDGE_ENABLE - default
\  h# ffff0000 h# 10c4 pl!  \ GPIOH_IN_NEGEDGE_ENABLE - default
\  h# 0000ffff h# 10c8 pl!  \ GPIOH_IN_POSEDGE_STATUS - R/WC
\  h# 0000ffff h# 10cc pl!  \ GPIOH_IN_NEGEDGE_STATUS - R/WC
\  h#     0000 h# 10d0 pw!  \ GPIO_06_FILTER_AMOUNT - default
\  h#     0000 h# 10d2 pw!  \ GPIO_06_FILTER_COUNT - default
\  h#     0000 h# 10d4 pw!  \ GPIO_06_EVENT_COUNT - default
\  h#     0000 h# 10d6 pw!  \ GPIO_06_EVENTCOMPARE_VALUE - default
\  h#     0000 h# 10d8 pw!  \ GPIO_07_FILTER_AMOUNT - default
\  h#     0000 h# 10da pw!  \ GPIO_07_FILTER_COUNT - default
\  h#     0000 h# 10dc pw!  \ GPIO_07_EVENT_COUNT - default
\  h#     0000 h# 10de pw!  \ GPIO_07_EVENTCOMPARE_VALUE - default

   h# 20000001 h# 10e0 pl!  \ GPIO_MAPPER_X
\  h# 00000000 h# 10e4 pl!  \ GPIO_MAPPER_Y - default
\  h# 00000000 h# 10e8 pl!  \ GPIO_MAPPER_Z - default
\  h# 00000000 h# 10ec pl!  \ GPIO_MAPPER_W - default
\  h#       00 h# 10f0 pc!  \ GPIO_EE_SELECT_0 - default
\  h#       00 h# 10f1 pc!  \ GPIO_EE_SELECT_1 - default
\  h#       00 h# 10f2 pc!  \ GPIO_EE_SELECT_2 - default
\  h#       00 h# 10f3 pc!  \ GPIO_EE_SELECT_3 - default
\  h#       00 h# 10f4 pc!  \ GPIO_EE_SELECT_4 - default
\  h#       00 h# 10f5 pc!  \ GPIO_EE_SELECT_5 - default
\  h#       00 h# 10f6 pc!  \ GPIO_EE_SELECT_6 - default
\  h#       00 h# 10f7 pc!  \ GPIO_EE_SELECT_7 - default
\  h# 00000000 h# 10f8 pl!  \ GPIOL_EVENT_DECREMENT - default
\  h# 00000000 h# 10fc pl!  \ GPIOH_EVENT_DECREMENT - default
;

: fix-sirq  ( -- )
   9 ec-cmd 9 <>  if
      h# 5140.004e rdmsr  swap h# 40 or swap  h# 5140.004e wrmsr
   then
;
