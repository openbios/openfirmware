purpose: Atheros 9382 "EEPROM" code
\ See license at end of file

headers
hex

create eeprom
here
   02 c, 04 c,                                 \ eepromVersion, templateVersion
   00 c, 03 c, 7f c, 00 c, 00 c, 00 c,         \ macAddr
   " h116-041-f0000" $,                        \ custData
   00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
   \ baseEepHeader
   0000 w, 001f w, 33 c, 03 c, 00 c, 00 c, 00 c, 00 c, 05 c,
   00 c, 00 c, 00 c, 0d c, 00 c, 06 c, 00 c, 08 c, ff c, 10 c, 0 l,
   \ modalHeader2G
   0000.0110 l, 0004.4444 l,         \ antCtrlCommon, antCtrlCommon2
   0010 w, 0010 w, 0010 w,           \ antCtrlChain
   1f c, 1f c, 1f c,                 \ xatten1DB
   12 c, 12 c, 12 c,                 \ xatten1Margin
   19 c, 00 c,                       \ tempSlope, voltSlope
   a4 c, 00 c, 00 c, 00 c, 00 c,     \ spurChans: FREQ2FBIN(2464, 1)
   ff c, 00 c, 00 c,                 \ noiseFloorThreshCh
   01 c, 01 c, 01 c,                 \ ob
   01 c, 01 c, 01 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, \ db_stage2-4
   00 c, 0e c, 0e c, 03 c, 00 c, 2c c, e2 c, 00 c, 02 c, 0e c, 1c c,
   0c80.c080 l, 0080.c080 l,         \ papdRateMaskHt20, 40
   00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
   \ base_ext1
   00 c, 00 c,
   00 c, 00 c, 00 c,  00 c, 00 c, 00 c,  00 c, 00 c, 00 c,  00 c, 00 c, 00 c,
   \ calFreqPier2G
   70 c, 89 c, ac c,                 \ 2412, 2437, 2472
   \ calPierData2G
   6 3 * 3 * here over allot swap erase
   \ calTarget_freqbin_Cck
   70 c, ac c,                       \ 2412, 2472
   \ calTarget_freqbin_2G
   70 c, 89 c, ac c,                 \ 2412, 2437, 2472
   \ calTarget_freqbin_2GHT20
   70 c, 89 c, ac c,                 \ 2412, 2437, 2472
   \ calTarget_freqbin_2GHT40
   70 c, 89 c, ac c,                 \ 2412, 2437, 2472
   \ calTargetPowerCck
decimal
   34 c, 34 c, 34 c, 34 c, 
   34 c, 34 c, 34 c, 34 c,
   \ calTargetPower2G 
   34 c, 34 c, 32 c, 32 c, 
   34 c, 34 c, 32 c, 32 c, 
   34 c, 34 c, 32 c, 32 c, 
   \ calTargetPower2GHT20
   32 c, 32 c, 32 c, 32 c, 32 c, 30 c, 32 c, 32 c, 30 c, 28 c, 0 c, 0 c, 0 c, 0 c,
   32 c, 32 c, 32 c, 32 c, 32 c, 30 c, 32 c, 32 c, 30 c, 28 c, 0 c, 0 c, 0 c, 0 c,
   32 c, 32 c, 32 c, 32 c, 32 c, 30 c, 32 c, 32 c, 30 c, 28 c, 0 c, 0 c, 0 c, 0 c,
   \ calTargetPower2GHT40
   30 c, 30 c, 30 c, 30 c, 30 c, 28 c, 30 c, 30 c, 28 c, 26 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 30 c, 30 c, 28 c, 30 c, 30 c, 28 c, 26 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 30 c, 30 c, 28 c, 30 c, 30 c, 28 c, 26 c, 0 c, 0 c, 0 c, 0 c,
hex
   \ ctlIndex_2G
   11 c, 12 c, 15 c, 17 c, 41 c, 42 c,
   45 c, 47 c, 31 c, 32 c, 35 c, 37 c,
   \ ctlfreqbin_2G
   70 c, 75 c, 9d c, a2 c,
   70 c, 75 c, a2 c, ff c,
   70 c, 75 c, a2 c, ff c,
   7a c, 7f c, 93 c, 98 c,
   70 c, 75 c, ac c, b9 c,
   70 c, 75 c, ac c, 00 c,
   70 c, 75 c, ac c, 00 c,
   7a c, 7f c, 93 c, a2 c,
   70 c, 75 c, ac c, 00 c,
   70 c, 75 c, ac c, 00 c,
   70 c, 75 c, ac c, 00 c,
   7a c, 7f c, 93 c, a2 c,
   \ ctlPowerData_2G
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 3c c, 3c c,
   7c c, 3c c, 3c c, 7c c,
   7c c, 3c c, 00 c, 00 c,
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 7c c, 3c c,
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 3c c, 3c c,
   3c c, 7c c, 7c c, 7c c,
   3c c, 7c c, 7c c, 7c c,
   \ modalHeader5G
   0000.0220 l, 0004.4444 l,         \ antCtrlCommon, antCtrlCommon2
   0150 w, 0150 w, 0150 w,           \ antCtrlChain
   19 c, 19 c, 19 c,                 \ xatten1DB
   14 c, 14 c, 14 c,                 \ xatten1Margin
   46 c, 00 c,                       \ tempSlope, voltSlope
   00 c, 00 c, 00 c, 00 c, 00 c,     \ spurChans: FREQ2FBIN(2464, 1)
   ff c, 00 c, 00 c,                 \ noiseFloorThreshCh
   03 c, 03 c, 03 c,                 \ ob
   03 c, 03 c, 03 c, 03 c, 03 c, 03 c, 03 c, 03 c, 03 c, \ db_stage2-4
   00 c, 0e c, 0e c, 03 c, 00 c, 2d c, e2 c, 00 c, 02 c, 0e c, 1c c,
   0cf0.e0e0 l, 6cf0.e0e0 l,         \ papdRateMaskHt20, 40
   00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,
   \ base_ext2
   23 c, 32 c,
   00 c, 00 c, 00 c,  00 c, 00 c, 00 c,  00 c, 00 c, 00 c,  00 c, 00 c, 00 c,
   \ calFreqPier5G
   4c c, 54 c, 68 c, 78 c, 8c c, a0 c, b4 c, c5 c,  \ 5180, 5220, 5320, 5400, 5500, 5600, 5700, 5785
   \ calPierData5G
   6 8 * 3 * here over allot swap erase
   \ calTarget_freqbin_5G
   4c c, 58 c, 68 c, 78 c, 8c c, a0 c, b4 c, cd c,  \ 5180, 5240, 5320, 5400, 5500, 5600, 5700, 5825
   \ calTarget_freqbin_5GHT20
   4c c, 58 c, 68 c, 78 c, 8c c, b4 c, bd c, cd c,  \ 5180, 5240, 5320, 5400, 5500, 5700, 5745, 5825
   \ calTarget_freqbin_5GHT40
   4c c, 58 c, 68 c, 78 c, 8c c, b4 c, bd c, cd c,  \ 5180, 5240, 5320, 5400, 5500, 5700, 5745, 5825
   \ calTargetPower5G
decimal 
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   30 c, 30 c, 28 c, 24 c,
   \ calTargetPower5GHT20
   30 c, 30 c, 30 c, 28 c, 24 c, 20 c, 30 c, 28 c, 24 c, 20 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 28 c, 24 c, 20 c, 30 c, 28 c, 24 c, 20 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 26 c, 22 c, 18 c, 30 c, 26 c, 22 c, 18 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 26 c, 22 c, 18 c, 30 c, 26 c, 22 c, 18 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 24 c, 20 c, 16 c, 30 c, 24 c, 20 c, 16 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 24 c, 20 c, 16 c, 30 c, 24 c, 20 c, 16 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 22 c, 18 c, 14 c, 30 c, 22 c, 18 c, 14 c, 0 c, 0 c, 0 c, 0 c,
   30 c, 30 c, 30 c, 22 c, 18 c, 14 c, 30 c, 22 c, 18 c, 14 c, 0 c, 0 c, 0 c, 0 c,
   \ calTargetPower5GHT40
   28 c, 28 c, 28 c, 26 c, 22 c, 18 c, 28 c, 26 c, 22 c, 18 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 26 c, 22 c, 18 c, 28 c, 26 c, 22 c, 18 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 24 c, 20 c, 16 c, 28 c, 24 c, 20 c, 16 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 24 c, 20 c, 16 c, 28 c, 24 c, 20 c, 16 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 22 c, 18 c, 14 c, 28 c, 22 c, 18 c, 14 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 22 c, 18 c, 14 c, 28 c, 22 c, 18 c, 14 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 20 c, 16 c, 12 c, 28 c, 20 c, 16 c, 12 c, 0 c, 0 c, 0 c, 0 c,
   28 c, 28 c, 28 c, 20 c, 16 c, 12 c, 28 c, 20 c, 16 c, 12 c, 0 c, 0 c, 0 c, 0 c,
hex
   \ ctlIndex_5G
   10 c, 16 c, 18 c, 40 c, 46 c, 48 c, 30 c, 36 c, 38 c,
   \ ctlfreqbin_5G
   4c c, 5c c, 60 c, 8c c, a0 c, b4 c, bd c, cd c,
   4c c, 5c c, 60 c, 8c c, 90 c, b4 c, bd c, cd c,
   4e c, 56 c, 5e c, 66 c, 8e c, 96 c, ae c, bf c,
   4c c, 50 c, 5c c, 68 c, 8c c, b4 c, ff c, ff c,
   4c c, 5c c, 8c c, b4 c, ff c, ff c, ff c, ff c,
   4e c, 5e c, 66 c, 8e c, 9e c, ae c, ff c, ff c,
   4c c, 50 c, 54 c, 5c c, 8c c, a0 c, b4 c, bd c,
   4c c, 5c c, 68 c, 8c c, 98 c, b4 c, bd c, cd c,
   4e c, 56 c, 5e c, 8e c, 96 c, ae c, b4 c, c7 c,
   \ ctlPowerData_5G
   7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 3c c,
   7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 3c c,
   3c c, 7c c, 3c c, 7c c, 7c c, 7c c, 7c c, 7c c,
   3c c, 7c c, 7c c, 3c c, 7c c, 3c c, 3c c, 3c c,
   7c c, 7c c, 7c c, 3c c, 3c c, 3c c, 3c c, 3c c,
   7c c, 7c c, 7c c, 7c c, 7c c, 3c c, 3c c, 3c c,
   7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 7c c, 7c c,
   7c c, 7c c, 3c c, 7c c, 7c c, 7c c, 7c c, 3c c,
   7c c, 3c c, 7c c, 7c c, 7c c, 7c c, 3c c, 7c c,

here swap - constant /eeprom-init


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining

\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
