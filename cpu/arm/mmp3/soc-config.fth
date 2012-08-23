create mmp3
h# 20000 constant l2-#sets

h# c0f0.0000 constant mmp3-audio-pa
h#   10.0000 constant /mmp3-audio

h# d103.0000 constant audio-sram-pa  \ Base of Audio SRAM
h#    2.0000 constant /audio-sram
\ No need to map audio-sram separately; it fits in the SRAM area

h# 0005.0000 constant /sram          \ Size of SRAM
