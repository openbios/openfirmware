\ See license at end of file
purpose: Analysis results of audio diagnostics

headers
hex

\ *******************************************************************************
\ The Fast Fourier Transform (FFT) is employed here to analysis audio samples.
\ FFT uses the buffer sxvect.  Sxvect is an array of complex numbers, which, upon
\ entry to FFT, are the data samples to be analysed in the time domain.  Upon
\ exit from FFT, they represents the magnitude in the frequency domain.
\
\ #sxvect indicates the number of data samples in sxvect.  It must be a power of 2.
\
\ The FFT results are interpreted differently depending on the audio tests.
\
\ There are several ways the result is presented to the user.  By default, the
\ users, assuming them to be manufacturing folks, are presented with OK/NOT OK.
\ By default, it is run as part of test-all.
\
\ For the more advanced users, detail information can be obtained in forms of plots
\ and more verbal information.  Variations of the tests can be run also.
\     ok install-uart-io		\ at keyboard, screen
\     ok select /audio:verbose,plot	\ at com1
\     ok init-test
\     ok clear-screen
\     ok test-left-noise drop		\ left can also be right, mic1 or mic2
\     ok d# 12000 test-left-loss drop
\     ok test-left-freq-resp drop
\     ok d# 12000 test-left-cross-talk drop
\     ok test-left-distort drop
\
\ 1.  Noise detection
\     Zeroes are sent out onto the audio circuitry and read back.
\     Prior to performing FFT on the input data, the dc component is removed from
\     the input samples.  The signal-to-noise-ratio is computed from the input
\     samples (see check-snr).  The computed SNR is less than a pre-defined
\     snr-threshold, an error is reported.
\
\     In addition, FFT is performed on the input data, in order to uncover noise
\     spike in the frequency domain.
\
\     In the frequency domain, noise tends to be distributed in the following
\     manner: sum of noise in 2**i = sum of noise in 2**(i-1).  Thus, the noise
\     level at low frequencies are fairly high and the lowest frequencies are
\     not included in the spike search.
\
\     The plot of the test results would show you the noise spikes and noise at
\     the low end of the frequency spectrum.
\
\ 2.  Loss/gain measurement
\     The sine wave of a particular frequency is generated at 1/2 full scale and
\     sent out onto the audio circuitry and read back.
\
\     FFT is performed on the input data to generate data in the frequency domain.
\     The magnitude at the above frequency is computed and compared with an
\     predeemed acceptable loss and gain levels.
\
\     The plot of the test results would show you the spike at the above
\     frequency and noise at the low end of the frequency spectrum.
\
\ 3.  Frequency response test
\     Zeroes are sent out to the audio circuitry, except in the middle of which
\     is a full magnitude spike.  The loopback data should show the efficiency
\     of the low-end and high-end filters.  Theoretically, if components are
\     misstuffed in the filters, this test will find them.
\
\     Ripples are checked in the mid-range and are deemed unacceptable if the
\     ripples are greater than 2.0 db.
\
\     In addition, at 100 hz, i.e., the low-end roll-off is expected to be
\     less than -2.0 db.   At 20 Khz, i.e., the high-end roll-off is expected to
\     be less than -4.0 db.
\
\     The plot generated for frequency response are quite different from the
\     other plots in this program.  The frequency response plot displays the
\     power for the first 750 hz linearly, i.e., 1 pixel column per 6 hz.
\     Subsequent columns displays the power of 750 * i * 2**(1/128).  You can
\     see the slopes of the low-end and high-end roll-offs.
\
\ 4.  Cross talk test
\     The sine wave of a particular frequency is sent to one audio channel
\     while the tested channel gets all zeroes.
\
\     FFT is performed on the input data, in order to uncover cross-talk spike
\     in the frequency domain.
\
\     The tested channel, under ideal situation, at the above frequency, should
\     have a spike no more than -72 db.
\
\     The plot of the test results would show you the cross-talk spike and noise
\     at the low end of the frequency spectrum.
\
\ 5.  Distortion measurement
\     The composite wave of two sine waves of two frequencies, f1 and f2, is
\     sent to the audio system and read back.  F1 is a higher frequency at 1/4
\     magnitude and f2 is a lower frequency at 1/2 magnitude.  F1 must not be
\     a multiple of F2.
\
\     FFT is performed on the input data in order to uncover intermodular and
\     harmonic distortions.
\
\     Intermodular distortions are found at f1 +/- i*f2.  The magnitude of an
\     intermodular distortion should be less than -70 db.
\
\     Harmonic distortions are found at i*f1 and i*f2.  The magnitude of a
\     harmonic distortion should be less than -78 db.
\
\     The plot of the test results would show you the magnitude at f1 and f2,
\     plus any intermodular and harmonic distortions, plus aliasing, plus noise
\     at the low end of the frequency spectrum.
\ 
\ *******************************************************************************

8 d# 1024 * constant #sxvect
0 value sxvect
0 value mag-buf
0 value pure-buf
#sxvect /x* constant /sxvect
#sxvect /n* constant /mag-buf

: xvect@  ( adr idx -- x )  xa+ x@  ;
: xvect!  ( x adr idx -- )  xa+ x!  ;

\ *******************************************************************************
0 value left?
0 value freq1		0 value mag1
0 value freq2		0 value mag2

: mag>avg ( m - am )  #sxvect 2/ /  ;
: hz>idx  ( hz -- idx )  #sxvect 2* * frame-rate / 1+ 2/  ;
: idx>hz  ( idx -- hz )  frame-rate #sxvect */  ;

\ *******************************************************************************
\ The best way of making use of plot-result is to redirect I/O to com1.
\ At ok prompt, type install-uart-io.  The plot would be on screen while user
\ interface is at com1 so the screen is used for plots only.
\ *******************************************************************************

 0 constant fplot-color		\ foreground color
 f constant bplot-color		\ background color
 7 constant mplot-color		\ horizontal marker color
				\ 11 light-purple, 1 blue, 2/3 green, 7 gray
d#    8 constant #bpixel
d#   72 constant #pixel/col
d# 1024 constant #pixel/row
#pixel/col #bpixel + #pixel/row * constant /plot
#pixel/col #bpixel + #sxvect *    constant /plot-buf
d#  128 constant marker-interval
d#    5 constant #marker-rows
#pixel/row marker-interval / constant #marker/row
#marker/row #marker-rows * constant #marker
0 value plot-buf
0 value #skip-col

\ *******************************************************************************
: alloc-test-buffers  ( -- )
   /sxvect alloc-mem to sxvect
   /mag-buf alloc-mem to mag-buf
   /mag-buf alloc-mem to pure-buf
   /plot-buf alloc-mem to plot-buf
;

: free-test-buffers  ( -- )
   sxvect /sxvect free-mem
   mag-buf /mag-buf free-mem
   pure-buf /mag-buf free-mem
   plot-buf /plot-buf free-mem
;

\ *******************************************************************************
: lsample@  ( a i -- s )  la+ 2+ <w@  ;
: rsample@  ( a i -- s )  la+ <w@  ;
: lsample!  ( s a i -- )  la+ 2+ w!  ;
: rsample!  ( s a i -- )  la+ w!  ;
defer s@			' lsample@ to s@
defer s!			' lsample! to s!

\ *******************************************************************************
\ Hamming windowing:
\   sample(k) = sample(k) * ( 1 + cos ( pi*k/N1) ) / 2
\ where N1 is 10% of total samples and k is index into N1 at the both ends
\ of total samples.
\ However, the FFT results appears must useful if windowing is not applied to
\ the input data to the FFT.  Therefore, no-filter is used instead on the input
\ data prior to FFT
\ *******************************************************************************

0 value #ts
0 value #ws
0 value bew
0 value sadr
0 value dadr

: ham  ( k N -- scaled_16.n )
   swap pi um* rot um/mod nip
   negate pi/2 + (sin) scaled-1 + 2/  
;

: no-filter  ( k N -- scaled_16.n )  2drop scaled-1  ;
defer filter				' no-filter to filter

\ *******************************************************************************
\ Move the input sample data to the FFT buffer prior to calling FFT.
\ *******************************************************************************
: samples>vector  ( s d #s -- )
   dup to #ts
   dup d# 10 / dup to #ws
   - to bew  to dadr  to sadr

   \ Filter the first 10% and last 10% of source data
   #ws 1+ 1  ?do
      i #ws filter dup			( filter filter )
      sadr #ws i - dup >r s@ m*		( filter sample )  ( k )
      d>x dadr r> xvect!		( filter )
      sadr bew i + 1- dup >r s@ m*	( sample )  ( k )
      d>x dadr r> xvect!		( )
   loop

   \ Transfer the middle 80% scaled 16.
   bew #ws  ?do
      sadr i s@ scaled-1 m* d>x dadr i xvect!
   loop
;

\ *******************************************************************************
\ The result of the FFT is interpreted and moved to mag-buf.
\ There are two interpretions:
\   1.  Pure magnitude of each frequency (|x|).
\   2.  Power of each frequency (|x|**2).
\ *******************************************************************************
: mag!  ( n index -- )  mag-buf swap la+ l!  ;
: mag@  ( index -- n )  mag-buf swap la+ l@  ;
: (dump-mag)  ( -- )
   #sxvect 2/ 0  do
      sxvect i xvect@ |x| i mag!
   loop
;
: (dump-db)  ( -- )
   0 0 mag!
   #sxvect 2/ 1  do
      sxvect i xvect@ |x|^2 drop  i mag!
   loop
;

defer dump-mag			' (dump-mag) to dump-mag

: do-fft-mag  ( adr -- )
   sxvect #sxvect samples>vector
   #sxvect sxvect false fft
   dump-mag
;

\ *******************************************************************************
\ Methods to plot mag-buf on screen

0 value my-screen-ih
: my-call-screen  ( a x y w h $ -- )  my-screen-ih  $call-method  ;

: clear-screen  ( -- )
   my-screen-ih 0=  if  exit  then
   bplot-color 0 0 d# 1024 d# 768 " fill-rectangle"  my-call-screen
;

d# 23 value min-log  d# 8 value scale-log
: mag>plot  ( n - n' )
   ilog2  min-log - 0 max
   dup  0=  if  nip 0  then
   scale-log 2* dn*  2drop nip  1+ 2/
   0 max #pixel/col  min
;

: amag@  ( adr cnt idx -- mag )
   swap >r 0 -rot
   la+ r> /n* bounds  do
      i @ max
   /n +loop
;

: make-markers  ( -- )
   \ Make horizontal markers
   plot-buf #pixel/col 1+ #pixel/row * + dup #pixel/row mplot-color fill
   #pixel/row + #marker 0  do
      mplot-color over i marker-interval * +  c!
   loop  drop
;
: small-plot-mag  ( adr -- )
   #sxvect 2/ #pixel/row /
   #pixel/row 0  ?do
      2dup dup i * amag@  mag>plot #pixel/col tuck swap -  ?do
         fplot-color plot-buf i #pixel/row * + j + c!
      loop
   loop  2drop
;

: q.64>d.32  ( q.64 -- d.32 )  drop  rot 0<  if  1 0 d+  then  ;

: mag-range@  ( d.bhz d.ehz adr -- max min )
   >r
   swap 0<  if  1+  then  hz>idx #sxvect 2/ 1- min r@ swap la+ -rot
   swap 0<  if  1+  then  hz>idx r> swap la+
   2dup =  if
      drop @ dup
   else
      2dup 0 -rot  ?do  i @ umax  4 +loop  -rot
      ffff.ffff -rot  ?do  i @ umin  4 +loop
   then
;

0 value column
: small-plot-db  ( adr -- )
   d# 128 to #skip-col

   \ The first 750 hz of data are plotted linearly
   d# 750 hz>idx 0  do
      dup i la+ @
      mag>plot #pixel/col swap - #pixel/row * plot-buf + i + fplot-color swap c!
   loop

   \ The next groups of 128 columns each represents an octave.
   d# 750 hz>idx to column
   0 d# 750  begin			( adr d.bhz )
      2dup 163.da9f 1  ud*  q.64>d.32 	( adr d.bhz d.ehz )
      2tuck 6 pick			( adr d.ehz d.bhz d.ehz adr )
      mag-range@			( adr d.ehz max min )
      mag>plot #pixel/col swap - 1+ #pixel/col min	( adr d.ehz min max' )
      swap mag>plot #pixel/col swap - 0 max  ?do	( adr d.ehz )
         fplot-color i #pixel/row * plot-buf + column + c!
      loop				( adr d.ehz )
      column 1+ to column		( adr d.ehz )
      2dup swap 0<  if  1+  then  hz>idx  #sxvect 2/  >=
   until
   3drop
;

defer small-plot-mag-buf		' small-plot-mag to small-plot-mag-buf

: small-plot-result  ( left? -- )
   0 to #skip-col
   mag-buf small-plot-mag-buf
   make-markers
   if  0  else  #pixel/col #bpixel +  then
   plot-buf #skip-col rot #pixel/row #pixel/col #bpixel + " draw-rectangle" my-call-screen
;

: plot-result  ( left? -- )
   my-screen-ih 0=  if  drop exit  then
   plot-buf /plot-buf bplot-color fill
   small-plot-result
;

\ *******************************************************************************
\   SNR[db] = 3 ( 42 - log2(NRG) )
\
\ where
\            8K
\   NRG =  sum  v[i]^2     (after having subtracted the DC offset)
\           i=0
\ *******************************************************************************
d# 66 constant snr-threshold
: input-dc  ( adr -- )			\ remove DC component
   0  #sxvect 0  do  over i s@ +  loop  #sxvect /	( adr dc )
   #sxvect 0  do  over i s@ over - 2 pick i s!  loop	( adr dc )
   2drop						( )
;
: compute-nrg  ( adr -- d.nrg )
   0 0  #sxvect 0  do  2 pick i s@ dup m* d+  loop  rot drop
;
: compute-snr  ( nrg -- snr )
   ?dup  if
      nip   ilog2  d# 32 +  nip
   else
      ilog2  swap 0<  if  1+  then
   then
   d# 42 swap - 3 *
;
: check-snr  ( adr -- error? )	\ signal to noise ratio
   dup input-dc
   compute-nrg
   compute-snr
   verbose?  if  dup ." SNR = " .d  ." db" cr  then
   snr-threshold <=
;

: (make-pure-fft)  ( -- )
   dma-out-virt do-fft-mag
   mag-buf pure-buf /mag-buf move
;
: make-pure-fft  ( adr -- error? )  drop  (make-pure-fft)  false  ;

: plot-pure-fft  ( left? -- )  (make-pure-fft) plot-result  ;

: no-preprocess-input  ( adr -- error? )  drop false  ;
defer preprocess-input		' no-preprocess-input  to preprocess-input

\ *******************************************************************************
#sxvect  constant noise-spike-threshold		\ 84 db
d# 50 value noise-spike-freq0

: check-noise ( -- error? )
   false #sxvect 2/  noise-spike-freq0 hz>idx  do
      i mag@ dup  noise-spike-threshold >  if
         verbose?  if
            8 u.r ."  at " i idx>hz .d ." hz" cr
         else
            drop
         then
         drop true
      else
         drop
      then
   loop
;

#sxvect 4 * constant cross-talk-spike-threshold		\ 72 db
: check-cross-talk ( -- error? )
   false #sxvect 2/  noise-spike-freq0 hz>idx  do
      i mag@ dup  cross-talk-spike-threshold >  if
         verbose?  if
            8 u.r ."  at " i idx>hz .d ." hz" cr
         else
            drop
         then
         drop true
      else
         drop
      then
   loop
;

: hz-mag@  ( hz -- mag )  hz>idx mag@  ;

d# 80 constant %loss-threshold		\ -1.9 db
d# 120 constant %gain-threshold		\ 1.6 db
: check-loss  ( -- error? )
   mag1  %loss-threshold  d# 100  */                ( loss )
   mag1  %gain-threshold  d# 100  */		    ( loss gain )
   freq1 hz-mag@  mag>avg                           ( loss gain freq1-am )
   dup >r -rot within 0= r> over  if                ( error? freq1-am )
      verbose?  if
         ." At " freq1 .d ." Hz," cr
         ." Output magnitude = " mag1 4 u.r cr
         ." Input  magnitude = " 4 u.r cr
      else
         drop
      then
   else                                             ( error? freq1-am )
      drop
   then
;

\ Given 10*log10(V1/V2) = db
h# 03.5269e1 constant 2log10
h# 0001.95bc constant 10**(4/20)	\ 4db
h# 0001.1f3d constant 10**(1/20)	\ 1db
: log10  ( x -- log10_x )  ilog2 d# 24 << swap d# 8 >> or  2log10 /  ;
: v2@db  ( v1 db -- v2 )  d# 20 / 1 swap 0  ?do  d# 10 *  loop  /  ;
: db@v2  ( v1 v2 -- db )  / log10 d# 20 *  ;

h# b504f334 constant sqrt2/2		\ fraction of 2**-2/2
0 value mid-range

0 value max-idx
0 value min-idx

: compute-mid-ranges  ( fl fh -- vh vl )
   0 to max-idx  0 to min-idx                  ( fl fh )
   hz>idx swap hz>idx                          ( idxh idxl )
   2dup  0 -rot  do                            ( idxh idxl max )
      i mag@  2dup <  if                       ( idxh idxl max current )
         i to max-idx  nip                     ( idxh idxl max' )
      else                                     ( idxh idxl max current )
         drop                                  ( idxh idxl max )
      then                                     ( idxh idxl max )
   loop                                        ( idxh idxl max )
   h# 7fff.ffff 2swap  do                      ( max min )
      i mag@  2dup >  if                       ( max min current )
         i to min-idx  nip                     ( max min' )
      else                                     ( max min current )
         drop                                  ( max min )
      then                                     ( max min )
   loop                                        ( max min )
   2dup + 2/ to mid-range
;

\ Multiply a 2-cell fractional number (frac int) by u, returning the
\ rounded integer result.
: frac*int  ( frac int u -- uprod )
   tuck u* >r  um* r> +                ( prod.frac prod.int )
   swap 0<  if  1+  then               ( prod.int' )
;

: db*10  ( numerator denomenator -- db*10 )
   swap ilog2 rot  ilog2    ( frac.log2_num frac.log2_den )
   d-                       ( frac.log2_ratio )

   \ Each factor of two in the ratio is 6 db, but we want db*10
   d# 60 frac*int           ( db*10 )
;

: .db*10  ( db*10 -- )
   push-decimal
   dup abs <# u# ascii . hold u#s swap sign u#> type  ."  db"
   pop-base
;

d#  2.0 constant ripple-threshold
d# -4.0 constant 20k-threshold
d# -2.0 constant 100-threshold
: ripple  ( -- error? )
   d# 300 d# 10000 compute-mid-ranges		( Vh Vl )

   2dup db*10                                   ( Vh Vl db*10 )
   ripple-threshold > dup  verbose? and  if     ( Vh Vl flag )
      >r                                                                ( Vh Vl )
      ." Mid-range ripple is greater than " ripple-threshold .db*10 cr  ( Vh Vl )
      ." Maximum " over  .d ." at " max-idx idx>hz .d ." Hz" cr         ( Vh Vl )
      ." Minimum " dup   .d ." at " min-idx idx>hz .d ." Hz" cr         ( Vh Vl )
      ." Ratio: "  db*10 .db*10 cr                                      ( )
      r>                                        ( flag )
   else                                         ( Vh Vl flag )
      nip nip                                   ( flag )
   then                                         ( flag )
;
: 20k?  ( -- error? )
   d# 20000 hz-mag@ mid-range  db*10  20k-threshold <    ( flag1 flag2 )
   dup verbose? and  if
      ." 20 KHz roll-off: " d# 20000 hz-mag@  mid-range  db*10 .db*10
      ."  (limit is " 20k-threshold .db*10 ." )" cr
   then
;
: 100?  ( -- error? )
   d# 100 hz-mag@  mid-range  db*10  100-threshold <    ( flag1 flag2 )
   dup verbose? and  if
      ." 100 Hz roll-off: " d# 100 hz-mag@  mid-range  db*10 .db*10
      ."  (limit is " 100-threshold .db*10 ." )" cr
   then
;
: check-freq-resp  ( -- error?)
   (dump-mag)				\ fill mag-buf with |x|

   ripple   20k? or  100? or
;

\ Given freq1 > freq2,
\ intermodular distortion @ freq1 +- i*freq2
\ harmonic distortion @ i*freq1 and i*freq2

#sxvect 10 * constant imd-threshold	\ 60 db
#sxvect  4 * constant hmd-threshold	\ 72 db
0 value distortion-threshold

: (check-distort)  ( error? hz -- error? )
   dup hz>idx mag@ dup distortion-threshold >  if
      verbose?  if
         ." At " swap .d ." Hz, distortion = " 8 u.r cr
      else
         2drop
      then
      drop true
   else
      2drop
   then
;
: check-intermod  ( -- error? )
   imd-threshold to distortion-threshold
   verbose?  if
      ." Intermodular Distortion (" freq1 .d ." Hz, " freq2 .d ." Hz):" cr
   then
   false freq1 freq2 / 1+  1  ?do
      freq1 freq2 i * - (check-distort)
   loop

   frame-rate 2/ freq1 - freq2 / 1+  1  ?do
      freq1 freq2 i * + (check-distort)
   loop
;
: check-harmonic  ( -- error? )
   hmd-threshold to distortion-threshold
   verbose?  if
      ." Harmonic Distortion (" freq1 .d ." Hz, " freq2 .d ." Hz):" cr
   then
   false frame-rate 2/ freq1 / 2  ?do
      freq1 i * (check-distort)
   loop
   frame-rate 2/ freq2 /  2 ?do
      freq2 i * (check-distort)
   loop
;
: check-distort  ( -- error? )
   check-intermod
   check-harmonic or
;

defer process-result		' false to process-result

\ *******************************************************************************
: check-result  ( adr left? -- error )
   dup >r  if  ['] lsample@ ['] lsample!  else  ['] rsample@ ['] rsample!  then  to s! to s@
   dup preprocess-input swap
   do-fft-mag
   r> plot?  if  plot-result  else  drop  then
   process-result or
;

headers
hex



\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
