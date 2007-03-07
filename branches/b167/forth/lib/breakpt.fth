\ See license at end of file

\ Assembly language breakpoints
\
\ Files needed:
\
\ objects.fth 		Defining words for multiple code field words
\ registers.fth		Defines the register save area.
\ 				CPU dependent
\ catchexc.fth		Saves the machine state in the register save area.
\ 				CPU & operating system dependent
\ machdep.fth		Defines CPU-dependent words for placing breakpoints
\ 			and finding the next instruction.
\ 				CPU-dependent
\ breakpt.fth		(This file) Manages the list of breakpoints, handles
\			single-stepping.	Machine-independent

needs array array.fth

only forth also hidden also
forth definitions

decimal

\ Moved to cpustate.fth
\ nuser restartable?  restartable? off

defer restart  ( -- )
defer restart-step  ( -- )

hidden definitions

headerless

20 constant max#breakpoints
max#breakpoints array >breakpoint
max#breakpoints array >breakpoint-action
max#breakpoints array >saved-opcode

2 array >step-breakpoint
2 array >step-saved-opcode
variable #breakpoints
variable #steps
variable pc-at-breakpoint
variable pc-at-step
headers
variable breakpoints-installed
headerless

: init-breakpoints  ( -- )
   #steps off
   #breakpoints off
   0 >step-breakpoint off
   1 >step-breakpoint off
   breakpoints-installed off
;
init-breakpoints

\ Search the breakpoint table to see if adr is breakpointed.
\ If it is, return the index into the table, or -1 if it's not there.
: find-breakpoint  ( adr -- breakpoint#|-1 )
   -1 swap				( -1 adr )
   #breakpoints @  0
   ?do					( -1 adr )
      dup  i >breakpoint @  = if	( -1 adr )
	 nip i swap leave		( i adr )
      then
   loop					( -1|breakpoint# adr )
   drop
;
\ Enter a breakpoint at adr.  If adr is already breakpointed,
\ don't enter it twice.
: set-breakpoint  ( adr -- )
   dup find-breakpoint				( adr breakpoint# )
   0<  if					( adr )
      #breakpoints @ max#breakpoints >=  abort" Too many breakpoints"
      dup					( adr adr )
      #breakpoints @  1 #breakpoints +!		( adr adr breakpoint# )
      >breakpoint !
   then						( adr )
   \ Set default action to be .breakpoint
   0 swap find-breakpoint >breakpoint-action !	( )
;
\ Display the breakpoint table.
: show-breakpoints ( -- )
   #breakpoints @  0  ?do
      i >breakpoint @ u.
      i >breakpoint-action @  ?dup  if ." { " >name .id ." }  "  then
   loop
;
\ If the breakpoint is installed in memory, take it out.
: repair-breakpoint  ( breakpoint# -- )
   dup >breakpoint @ at-breakpoint?
   if   dup >saved-opcode @   over >breakpoint @  op!   then
   drop
;

\ Remove the breakpoint at adr from the table, if it's there.
: remove-breakpoint  ( adr -- )
   find-breakpoint  ( breakpoint# )
   dup 0<  ( breakpoint# flag )
   if    drop
   else    ( breakpoint# )
      dup repair-breakpoint
      \ Shuffle the remaining breakpoints down to fill the vacated slot
      #breakpoints @  swap 1+  ( last-breakpoint# breakpoint# )
      ?do
	 i >breakpoint  @  i 1- >breakpoint  !
	 i >breakpoint-action  @  i 1- >breakpoint-action  !
      loop
      -1 #breakpoints +!
   then
;

\ When we restart the program, we have to put breakpoints at all the
\ places in the breakpoint list.  If there is a breakpoint at the
\ current PC, we have to temporarily not put one there, because we
\ want to execute it at least once (presumably we just hit it).
\ So we have to single step by putting breakpoints at the next instruction,
\ then when we hit that instruction, we put the breakpoint at the previous
\ place.  In fact, the "next instruction" may actually be 2 instructions
\ because the current instruction could be a branch.

: install-breakpoints  ( -- )
   breakpoints-installed @  if  exit  then
   breakpoints-installed on
   #breakpoints @  0   ?do
      i >breakpoint @			( breakpoint-adr )
      dup op@				( adr opcode )
      over at-breakpoint? 0= if		( adr opcode )
         i >saved-opcode !		( breakpoint-adr )
         put-breakpoint
      else
         2drop
      then
   loop
;
: repair-breakpoints  ( -- )
   #breakpoints @  0   ?do  i repair-breakpoint  loop
   breakpoints-installed off
;

\ Single stepping:
\ To single step, we have to breakpoint the instruction just after the
\ current instruction.  If that instruction is a conditional branch, we
\ have to breakpoint both the next instruction and the branch target.
\ The machine-dependent next-instruction routine finds the next instruction
\ and the branch target.

variable following-jsrs?
: set-step-breakpoints  ( -- )
   following-jsrs? @   next-instruction  ( next-adr branch-target | next-adr 0 )
   swap              ( step-breakpoint-adr1 step-breakpoint-adr0 )
   2 0  do
      dup i >step-breakpoint !            ( step-breakpoint-adr )
      ?dup   if                           ( step-breakpoint-adr )
         dup op@  i >step-saved-opcode !  ( step-breakpoint-adr )
         put-breakpoint
      then
   loop
;
: repair-step-breakpoints  ( -- )
   2 0  do
      i >step-breakpoint @  ?dup  if  ( step-breakpoint-adr )
         at-breakpoint?
         if   i >step-saved-opcode @  i >step-breakpoint @  op!  then
         0 i >step-breakpoint !
      then
   loop
;
: remove-all-breakpoints  ( -- )
   repair-breakpoints  repair-step-breakpoints  #breakpoints off
;
: uninstall-breakpoints  ( -- )
   breakpoints-installed @ if
      remove-all-breakpoints
   then
;

: current-address-breakpointed?  ( -- flag )
   rpc  find-breakpoint 0>=
;

: current-address-stepped?  ( -- flag )
   rpc  0 >step-breakpoint @  =
   rpc  1 >step-breakpoint @  =  or
;

: ?restart-ok  ( -- )  restartable? @  0=  abort" No program is active."  ;

: (step  ( -- )  set-step-breakpoints  ?restart-ok  restart-step  ;
headers

forth definitions
defer go-hook ' noop is go-hook
: steps  ( n -- )  #steps !  following-jsrs? on  (step  ;
: step  ( -- )  1 steps  ;
: hops  ( n -- )  #steps !  following-jsrs? off  (step  ;
: hop  ( -- )  1 hops  ;
: go  ( -- )
   go-hook  ?restart-ok  #steps off
   current-address-breakpointed?  if
      -1 #steps !
      following-jsrs? on  (step
   else
      install-breakpoints  restart
   then
;

: +bp  ( adr -- )
   uninstall-breakpoints
   dup
   bp-address-valid?  if
      set-breakpoint
   else
      ." Invalid breakpoint address " .x  cr
   then
;

: +bpx  ( adr -- )  \ name
   '  over +bp             ( adr acf )
   swap find-breakpoint    ( acf bp# | -1 )
   dup 0<  if              ( acf -1 )
      2drop                (  )
   else                    ( acf bp# )
      >breakpoint-action ! (  )
   then
;

: till  ( adr -- )  +bp  go  ;
: return  ( -- )  return-adr  till  ;  \ Finish and return from subroutine
: returnl  ( -- )  leaf-return-adr  till  ;  \ Finish and ret. from leaf subr.
: finish-loop  ( -- )  loop-exit-adr  till  ;  \ Finish the enclosing loop

headerless
alias continue go
variable #gos
headers
: gos  ( n -- )  1- #gos !  go  ;

: .pc  ( -- )  rpc  u.  ;
defer .step
defer .breakpoint

headerless
hidden definitions
' .instruction is .step
' .instruction is .breakpoint
: breakpoint-message  ( -- )

   \ If the trap type is inconsistent with a breakpoint, then we
   \ just print the exception type and exit.

   breakpoint-trap?  0=  if  .exception quit  then      \ Exit to interpreter

   \ If we are doing multiple single-steps, then we decrement the
   \ step count and continue stepping until the count reaches 0.

   #steps @  0>  if
      restartable? on
      .step
      -1 #steps +!  #steps @  if  (step  then   \ Exit to program
      quit                                      \ Exit to interpreter
   then

   \ If we are at a single-step location, but the step count variable was 0,
   \ If the step count variable was -1,
   \ then it was a "hidden step".  A "hidden step" happens when "go" is
   \ executed from a location where there is a breakpoint set.  We had to
   \ step once to execute the breakpointed instruction, and then we replace
   \ the location with a breakpoint insruction and go.
   \ This code used to sense that condition by comparing the pc with the
   \ step breakpoint locations, but that technique doesn't work with trace-bit
   \ stepping.

   #steps @ -1 =  if
      #steps off  restartable? on  go
   then  \ Exit to program

   \ If we are at a breakpoint location, then we consult the #gos variable
   \ to determine how many more times to go, and either go or "quit" to
   \ the interactive interpreter.

   pc-at-breakpoint @  if
      restartable? on
      rpc find-breakpoint >breakpoint-action @  ?dup  if
	 execute
      else
	 .breakpoint
      then
      #gos @  if  -1 #gos +!  go  then          \ Exit to program
      quit                                      \ Exit to interpreter
   then

   \ If we get here, a "breakpoint trap" occurred at a location where
   \ we don't think there should have been a breakpoint.  This means
   \ that the location happens to contain an instruction that causes the
   \ same kind of trap that is used for breakpoints (whatever that is for
   \ the particular system).  This could happen if a previous breakpoint
   \ didn't get cleaned up properly, or if memory got overwritten with
   \ breakpoint (or equivalent) instructions, or if the program jumped to
   \ an invalid location that happened to contain breakpoint (or equivalent)
   \ instructions.

   .exception quit                              \ Exit to interpreter
;
headers
: (handle-breakpoint  ( -- )
   current-address-stepped?  pc-at-step !
   current-address-breakpointed?  pc-at-breakpoint !
   repair-step-breakpoints
   repair-breakpoints

   breakpoint-message
;
' (handle-breakpoint is handle-breakpoint

forth definitions

: -bp  ( adr -- )
   uninstall-breakpoints
   remove-breakpoint
;
\ Remove most-recently-set breakpoint
: --bp  ( -- )
   #breakpoints @ if
      #breakpoints @ 1-  repair-breakpoint
      -1 #breakpoints +!
   then
;
: bpon  ( -- )
   uninstall-breakpoints
   install-breakpoints
;
: .bp   ( -- )  show-breakpoints  ;
: bpoff  ( -- )  remove-all-breakpoints  ;
: skip  ( -- )  bumppc go  ;

headerless
: init  ( -- )  init  init-breakpoints  ;
headers
\ init-breakpoints	\ redundant!

also keys-forth definitions
: ^t  step  ;
only forth also definitions
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
