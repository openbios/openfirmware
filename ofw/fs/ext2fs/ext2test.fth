\ OLPC boot script

\ dev.laptop.org #6210 test script
\ Exercises several OFW features on an ext2 filesystem on a USB stick
\ see associated test.sh

visible
no-page
start-logging

.( test.fth ticket #6210 ofw ext2 filesystem tests ) cr

show-aborts on

.( test 0001 define u: ) cr
volume: u:

.( test 0002 reference u: ) cr
u:

\ .( test 0003 directory ) cr
\ dir

\ .( test 0004 directory by name ) cr
\ dir *.fth

.( test 0005 chdir down ) cr
chdir directory

.( test 0006 directory of subdirectory after chdir ) cr
dir

.( test 0007 chdir up ) cr
chdir ..

.( test 0008 directory of main directory after chdir ) cr
dir

.( test 0009 disk free ) cr
disk-free u:\

.( test 0010 display a file ) cr
more u:\hello

.( test 0011 display a file with a hyphen in file name ) cr
more u:\hello-world

.( test 0012 display a link ) cr
more u:\hello-link

.( test 0013 directory of subdirectory by name ) cr
dir u:\directory

.( test 0014 display a file in subdirectory ) cr
more u:\directory\hw

.( test 0015 copy a file ) cr
copy u:\hello-world u:\copy

.( test 0016 display the copy ) cr
more u:\copy

.( test 0017 rename the copy ) cr
rename u:\copy u:\renamed

.( test 0018 delete the renamed copy ) cr
del u:\renamed

.( test 0019 delete a non-existent file ) cr
del u:\vapour

: load-file ( "devspec" -- adr len )
   safe-parse-word
   open-dev  dup 0=  abort" Can't open it"   ( ih )
   >r                                        ( r: ih )
   load-base " load" r@ $call-method         ( len r: ih )
   r> close-dev                              ( len )
   load-base swap
;

: calculate-md5 ( adr len -- adr len )
   $md5digest1 ;

: print-md5 ( adr len -- )
  bounds ?do i c@ (.2) type loop space ;

: md5sum  ( "devspec" -- )  load-file  calculate-md5  print-md5  ;

.( test 0020 calculate md5sum of a test file ) cr
md5sum u:\hello-world cr

.( test 0021 calculate md5sum of a test file and save to a file ) cr
del u:\hello-world.md5
load-file u:\hello-world calculate-md5 to-file u:\hello-world.md5 print-md5

.( test 0022 dump forth dictionary to file ) cr
del u:\words.txt
to-file u:\words.txt words

\ reference: forth/lib/tofile.fth
\ to-file u:\words words
\ append-to-file u:\words words

.( done ) cr
save-log u:\ofw.log
stop-logging

\ .( boot ) cr
\ boot n:\boot\olpc.fth
