create mmp3
h# 20000 constant l2-#sets

h# c0f0.0000 constant mmp3-audio-pa
h#   10.0000 constant /mmp3-audio

h# d103.0000 constant audio-sram-pa  \ Base of Audio SRAM
h#    2.0000 constant /audio-sram
\ No need to map audio-sram separately; it fits in the SRAM area

d# 4096  constant /audio-sram-dma  \ space for DMA descriptors
d# 2048  constant /audio-sram-mps  \ maximum period size
/audio-sram /audio-sram-dma -  2 /  constant /audio-sram-pcm  \ buffers

h# 0005.0000 constant /sram          \ Size of SRAM
