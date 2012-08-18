purpose: Driver for SETi image sensor 

hex
: seti-config  ( ycrcb? -- )
   >r               ( r: ycrcb? )

   \ SNR
   00 00 ov!
   00 04 ov!
   03 05 ov!
\   33 07 ov!
   32 07 ov!
   34 10 ov!
   27 11 ov!
   21 12 ov!
   c6 16 ov!
   aa 17 ov!

   00 20 ov!         \ P_BNKT
   01 21 ov!         \ P_HBNKT
   01 22 ov!         \ P_ROWFIL
   01 23 ov!         \ P_VBNKT

   \ AE
   01 00 ov!
   14 11 ov!         \ 6fps at lowlux
   78 12 ov!         \ D65 target 0x74
   78 13 ov!         \ CWF target 0x74
   78 14 ov!         \ A target   0x74
   08 1E ov!         \ ini gain  0x08
   7d 34 ov!
   60 40 ov!         \ Max x8

   d4 70 ov!         \ anti-sat on
   07 74 ov!         \ anti-sat ini
   69 79 ov!         \ anti-sat 
   
   \ AWB
   02 00 ov!
   d0 10 ov!
   c0 11 ov!
   80 12 ov!
   7f 13 ov!
   7f 14 ov!
   fe 15 ov!         \ R gain Top
   80 16 ov!         \ R gain bottom 
   cb 17 ov!         \ B gain Top
   70 18 ov!         \ B gain bottom 0x80
   94 19 ov!         \ Cr top value 0x90
   6c 1a ov!         \ Cr bottom value 0x70
   94 1b ov!         \ Cb top value 0x90
   6c 1c ov!         \ Cb bottom value 0x70
   94 1d ov!         \ 0xa0
   6c 1e ov!         \ 0x60
   e8 20 ov!         \ AWB luminous top value
   30 21 ov!         \ AWB luminous bottom value 0x20
   a4 22 ov!
   20 23 ov!
   20 24 ov!
   0f 26 ov!
   01 27 ov!         \ BRTSRT
   b4 28 ov!         \ BRTRGNTOP result 0xad
   b0 29 ov!         \ BRTRGNBOT 
   92 2a ov!         \ BRTBGNTOP result 0x90
   8e 2b ov!         \ BRTBGNBOT
   88 2c ov!         \ RGAINCONT
   88 2d ov!         \ BGAINCONT

   00 30 ov!
   10 31 ov!
   00 32 ov!
   10 33 ov!
   02 34 ov!
   76 35 ov!
   01 36 ov!
   d6 37 ov!
   01 40 ov!
   04 41 ov!
   08 42 ov!
   10 43 ov!
   12 44 ov!
   35 45 ov!
   64 46 ov!
   33 50 ov!
   20 51 ov!
   e5 52 ov!
   fb 53 ov!
   13 54 ov!
   26 55 ov!
   07 56 ov!
   f5 57 ov!
   ea 58 ov!
   21 59 ov!

   88 62 ov!         \ G gain

   b3 63 ov!         \ R D30 to D20
   c3 64 ov!         \ B D30 to D20
   b3 65 ov!         \ R D20 to D30
   c3 66 ov!         \ B D20 to D30

   dd 67 ov!         \ R D65 to D30
   a0 68 ov!         \ B D65 to D30
   dd 69 ov!         \ R D30 to D65
   a0 6a ov!         \ B D30 to D65

   \ IDP
   03 00 ov!
   ff 10 ov!
   0d 11 ov!
   cb 12 ov!
   04 14 ov!         \ don't change

   \ DPCNR
\   28 17 ov!        \DPCNRCTRL
   00 18 ov!         \ DPTHR
   56 19 ov!         \ C DP Number ( Normal [7:6] Dark [5:4] ) | [3:0] DPTHRMIN
   56 1A ov!         \ G DP Number ( Normal [7:6] Dark [5:4] ) | [3:0] DPTHRMAX
   12 1B ov!         \ DPTHRSLP( [7:4] @ Normal | [3:0] @ Dark )
   04 1C ov!         \ NRTHR
   00 1D ov!         \ [5:0] NRTHRMIN 0x48
   00 1E ov!         \ [5:0] NRTHRMAX 0x48
   08 1F ov!         \ NRTHRSLP( [7:4] @ Normal | [3:0] @ Dark )  0x2f
   04 20 ov!         \ IllumiInfo STRTNOR
   0f 21 ov!         \ IllumiInfo STRTDRK

   \  Gamma
   00 30 ov!         \ 0x0
   04 31 ov!         \ 0x3
   0b 32 ov!         \ 0xb
   24 33 ov!         \ 0x1f
   49 34 ov!         \ 0x43
   66 35 ov!         \ 0x5f
   7c 36 ov!         \ 0x74
   8d 37 ov!         \ 0x85
   9b 38 ov!         \ 0x94
   aa 39 ov!         \ 0xA2
   b6 3a ov!         \ 0xAF
   ca 3b ov!         \ 0xC6
   dc 3c ov!         \ 0xDB
   ef 3d ov!         \ 0xEF
   f8 3e ov!         \ 0xF8
   ff 3f ov!         \ 0xFF

   \ Shading Register Setting
   11 40 ov!
   11 41 ov!
   22 42 ov!
   33 43 ov!
   44 44 ov!
   55 45 ov!
   12 46 ov!         \ left R gain[7:4], right R gain[3:0]
   20 47 ov!         \ top R gain[7:4], bottom R gain[3:0]
   01 48 ov!         \ left Gr gain[7:4], right Gr gain[3:0] 0x21
   20 49 ov!         \ top Gr gain[7:4], bottom Gr gain[3:0]
   01 4a ov!         \ left Gb gain[7:4], right Gb gain[3:0] 0x02
   20 4b ov!         \ top Gb gain[7:4], bottom Gb gain[3:0]
   01 4c ov!         \ left B gain[7:4], right B gain[3:0]
   00 4d ov!         \ top B gain[7:4], bottom B gain[3:0]
   04 4e ov!         \ X-axis center high[3:2], Y-axis center high[1:0]
   50 4f ov!         \ X-axis center low[7:0] 0x50
   d0 50 ov!         \ Y-axis center low[7:0] 0xf6
   80 51 ov!         \ Shading Center Gain
   00 52 ov!         \ Shading R Offset
   00 53 ov!         \ Shading Gr Offset
   00 54 ov!         \ Shading Gb Offset
   00 55 ov!         \ Shading B Offset

   \ Interpolation
   57 60 ov!         \ INT outdoor condition
   ff 61 ov!         \ INT normal condition

   77 62 ov!         \ ASLPCTRL 7:4 GE, 3:0 YE
   38 63 ov!         \ YDTECTRL (YE) [7] fixed,
   38 64 ov!         \ GPEVCTRL (GE) [7] fixed,

   0c 66 ov!         \ SATHRMIN
   ff 67 ov!
   04 68 ov!         \ SATHRSRT
   08 69 ov!         \ SATHRSLP

   af 6a ov!         \ PTDFATHR [7] fixed, [5:0] value
   78 6b ov!         \ PTDLOTHR [6] fixed, [5:0] value

   84 6d ov!         \ YFLTCTRL

   \  Color matrix (D65) - Daylight
   42 71 ov!         \ 0x40
   bf 72 ov!         \ 0xb9
   00 73 ov!         \ 0x07
   0f 74 ov!         \ 0x15
   31 75 ov!         \ 0x21
   00 76 ov!         \ 0x0a
   00 77 ov!         \ 0xf8
   bc 78 ov!         \ 0xc5
   44 79 ov!         \ 0x46

   \  Color matrix (D30) - CWF
   56 7a ov!         \ 0x3a
   bf 7b ov!         \ 0xcd
   eb 7c ov!         \ 0xfa
   1a 7d ov!         \ 0x12
   22 7e ov!         \ 0x2c
   04 7f ov!         \ 0x02
   dc 80  ov!        \ 0xf7
   c9 81 ov!         \ 0xc7
   5b 82 ov!         \ 0x42

   \ Color matrix (D20) - A
   4d 83 ov!         \ 0x38
   c0 84 ov!         \ 0xc4
   f3 85 ov!         \ 0x04
   18 86 ov!         \ 0x07
   24 87 ov!         \ 0x25
   04 88 ov!         \ 0x14
   e0 89 ov!         \ 0xf0
   cb 8a ov!         \ 0xc2
   55 8b ov!         \ 0x4f

   10 8c ov!         \ CMA select

   a4 8d ov!         \ programmable edge
   06 8e ov!         \ PROGEVAL
   00 8f ov!         \ Cb/Cr coring

   15 90 ov!         \ GEUGAIN
   15 91 ov!         \ GEUGAIN
   f0 92 ov!         \ Ucoring [7:4] max, [3:0] min
   00 94 ov!         \ Uslope (1/128)
   f0 96 ov!         \ Dcoring [7:4] max, [3:0] min
   00 98 ov!         \ Dslope (1/128)

   08 9a ov!
   18 9b ov!

   0c 9f ov!         \ YEUGAIN
   0c a0 ov!         \ YEUGAIN
   33 a1 ov!         \ Yecore [7:4]upper [3:0]down

   10 a9 ov!         \ Cr saturation 0x12
   10 aa ov!         \ Cb saturation 0x12
   82 ab ov!         \ Brightness
   40 ae ov!         \ Hue
   86 af ov!         \ Hue
   10 b9 ov!         \ 0x20 lowlux color
   20 ba ov!         \ 0x10 lowlux color

   \ inverse color space conversion
   40 cc ov!
   00 cd ov!
   58 ce ov!
   40 cf ov!
   ea d0 ov!
   d3 d1 ov!
   40 d2 ov!
   6f d3 ov!
   00 d4 ov!

   \  ee nr
   08 d9 ov!
   1f da ov!
   05 db ov!
   08 dc ov!
   3c dd ov!
   fb de ov!         \ NOIZCTRL

   \ dark offset
   10 df ov!
   60 e0 ov!
   90 e1 ov!
   08 e2 ov!
   0a e3 ov!

   \ memory speed
   15 e5 ov!
   20 e6 ov!
   04 e7 ov!

   \ Sensor On
   00 00 ov!
   05 03 ov!

                 
   ( r: ycrcb? )  r>  0=  if    ( )
      03 00 ov!  \ IDP
      cb 12 ov!  \ RGB565 setting (same as yCrCb setting?)
   then
;

: seti-set-mirrored  ( mirrored? -- )
   0 0 ov!  4 ov@  1                       ( mirrored? reg-value bit )
   rot  if  or  else  invert and  then     ( reg-value' )
   4 ov!
;

: probe-seti  ( -- found? )
   h# 33 to camera-smb-slave  ( )
   camera-smb-on              ( )

   \ Try to read a byte of the manufacturing ID.  If the read fails,
   \ the device is not present or not responding.
   1 ['] ov@ catch  if        ( x )
      drop                    ( )
      false exit              ( -- false )
   then                       ( regval )
   h# 12 <>  if  false exit  then  ( )

   " SETi,SIV120D" " sensor" string-property

   ['] seti-set-mirrored to set-mirrored
   ['] seti-config       to camera-config
   true
;

\ Chain of sensor recognizers
: sensor-found?  ( -- flag )
   probe-seti  if  true exit  then
   sensor-found?
;
