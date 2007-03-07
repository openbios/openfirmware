\ See license at end of file
purpose: Load file for CPU-independent Forth tools

[ifndef] partial-no-heads	transient  [then]
fload ${BP}/forth/lib/filetool.fth		\ needed for dispose, savefort.fth

\NotTags fload ${BP}/forth/lib/dispose.fth
[ifndef] partial-no-heads	resident  [then]

[ifndef] partial-no-heads	transient  [then]
\NotTags fload ${BP}/forth/lib/headless.fth
\NotTags fload ${BP}/forth/lib/showspac.fth
[ifndef] partial-no-heads	resident  [then]

fload ${BP}/forth/lib/romable.fth

fload ${BP}/forth/lib/hidden.fth

fload ${BP}/forth/kernel/hashcach.fth

fload ${BP}/forth/lib/th.fth
fload ${BP}/forth/lib/ansiterm.fth

fload ${BP}/forth/kernel/splits.fth
fload ${BP}/forth/kernel/endian.fth

fload ${BP}/forth/lib/strings.fth

fload ${BP}/forth/lib/fastspac.fth

fload ${BP}/forth/lib/patch.fth
fload ${BP}/forth/lib/cirstack.fth		\ Circular stack
fload ${BP}/forth/lib/pseudors.fth		\ Interpretable >r and r>

fload ${BP}/forth/lib/headtool.fth

fload ${BP}/forth/lib/needs.fth

fload ${BP}/forth/lib/suspend.fth

fload ${BP}/forth/lib/util.fth
fload ${BP}/forth/lib/format.fth

fload ${BP}/forth/lib/stringar.fth

fload ${BP}/forth/lib/parses1.fth	\ String parsing

fload ${BP}/forth/lib/dump.fth
fload ${BP}/forth/lib/words.fth
fload ${BP}/forth/lib/decomp.fth

\ Uses  over-vocabulary  from words.fth
[ifndef] partial-no-heads	transient  [then]
\NotTags fload ${BP}/forth/lib/dumphead.fth
[ifndef] partial-no-heads	resident  [then]

fload ${BP}/forth/lib/seechain.fth

fload ${BP}/forth/lib/loadedit.fth		\ Command line editor module

fload ${BP}/forth/lib/caller.fth

fload ${BP}/forth/lib/callfind.fth
fload ${BP}/forth/lib/substrin.fth
fload ${BP}/forth/lib/sift.fth

fload ${BP}/forth/lib/array.fth

fload ${BP}/forth/lib/linklist.fth		\ Linked list routines

fload ${BP}/forth/lib/lex.fth

fload ${BP}/forth/lib/autold.fth		\ Autoload mechanism

[ifndef] partial-no-heads	transient  [then]
fload ${BP}/forth/lib/initsave.fth		\ Common code for save-forth et al
fload ${BP}/forth/lib/reminder.fth		\ Reminders
[ifndef] partial-no-heads	resident  [then]
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
