purpose: Tag all words that are executed; show all tagged words.
\ See license at end of file

hex

\ Generic tools for acting on all words

defer each   ( nfa -- )   ' drop to each
: every   ( voc -- )
   follow   begin  another?  while  each  repeat
;
: everywhere   ( xt -- )
   to each
   voc-link  begin  another-link?  while	( v-link )
      voc> dup every				( voc )
      >voc-link					( v-link' )
   repeat
;

\ verbose version
hidden also
: .vname   ( voc -- )
   ??cr  cr .in  ['] vocabulary .name space  .name cr
;
: show-every   ( xt -- )
   to each
   voc-link  begin  another-link?  while	( v-link )
      voc>
      dup .vname
      dup follow
      begin  another?  while
	 each
	 exit? if  drop exit  then 
      repeat
      >voc-link					( v-link' )
   repeat
;
previous forth

\ \ For reference...
\ label next
\    lwzu  w,/token(ip)	\ w has token of next word to execute
\    lwzux t1,w,base	\ t1 has offset of its code field
\    add   t1,t1,base	\ t1 has acf
\    mtspr lr,t1		\ go there
\    bclr  20,0
\ end-code

\ Special version of "next" tags any word that is executed
label tagnext
   lwzu  w,/token(ip)	\ w has token of next word to execute
   
   add   t1,w,base	\ t2 has acf
   set   t2,h#-10.0000	\ offset to tags
   add   t1,t1,t2	\ t1 has address of tag byte
   \ lbz   t2,0(t1)
   set   t2,h#a5	\ set magic# to tag the word
   stb   t2,0(t1)
   
   \ back to "next", which is already in progress...
   lwzux t1,w,base	\ t1 has offset of its code
   add   t1,t1,base	\ t1 has code address
   mtspr lr,t1		\ go there
   bclr  20,0
end-code

\ Turn on tagnext
: tnext  ( -- )
   tagnext up@ - h# 3ffffff and  h# 48000000 or  up@ instruction!
;
\ Revert to normal next
: nnext   ( -- )   [ bug ] unbug [ forth ]  ;

\ \ an example
\ : tryit   ( -- )   tnext bl word drop nnext  ;

: clear-tags   ( -- )
   origin h# 10.0000 -  here origin -  erase
;

\ variable tagged
\ : count-tagged   ( nfa -- )   name> 10.0000 - c@ a5 = if  1 tagged +!  then  ;
\ : tagged?   ( -- )
\    0 tagged !
\    ['] count-tagged everywhere
\    tagged ?
\ ;

: show-tagged?   ( nfa -- )
   dup name> 10.0000 - c@ a5 = if
      dup name>string nip .tab .id exit? if    
	 exit 
      then
   else
      drop
   then
;
decimal
: show-tagged   ( -- )
   nnext
   0 lmargin ! 64 rmargin ! 14 tabstops ! ??cr
   ['] show-tagged? show-every
;

: stand-init-io   ( -- )
   clear-tags  tnext
   stand-init-io
;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
