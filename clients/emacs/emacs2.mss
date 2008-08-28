
@style(indent 8 chars, spacing 1 lines)
@begin(center)
@b(MicroEMACS 3.7)

@i(Screen Editor)
written by Dave Conroy
and Daniel Lawrence
@end(center)


@begin(quotation)
	This software is in the public domain and may be freely copied
and used by one and all. We would ask that if it is incorporated into
other software that proper credit be given to its authors.
@end(quotation)

@flushleft(@b[Introduction])

	MicroEMACS 3.7 is a screen editor for programming and word
processing.  It is availible for the IBM-PC and its clones, UNIX V7,
UNIX BSD4.2, UNIX V5, VMS, the HP150, the Wang-PC and the Commodore
AMIGA.  It requires between 40 to 70K of space to run on these machines. 
Some of its capabilities include:

@begin(verbatim)
	Multiple windows on screen at one time

	Multiple files in the editor at once

	Limited on screen formating of text

	User changable command set

	User written editing macroes

	Compatability across all supported environments
@end(verbatim)

	This manual is designed as a reference manual. All the commands
in MicroEMACS are listed, in functional groups, along with detailed
descriptions of what each commands does.
@newpage
@flushleft(@b[How to Start])

	MicroEMACS is invoked from the operating system command level
with a command of the form:

@begin(verbatim)
	emacs {options} <filelist>

where options may be:

-v		all the following files are in view mode (read only)
-e		all the following files can be edited
-g<n>		go directly to line <n> of the first file
-s<string>	go to the end of the first occurance of <string>
		in the first file

@@<sfile>	execute macro file <sfile> instead of the
		standard startup file

and <filelist> is a list of files to be edited.

for example:

	emacs @@start1.cmd -g56 test.c -v head.h def.h

@end(verbatim)

	means to first execute macro file start1.cmd instead of the
standard startup file, emacs.rc and then read in test.c, position the
cursor to line 56, and be ready to read in files head.h and def.h in
view (read-only) mode.  In the simple case, MicroEMACS is usually run by
typing:

@flushleft(	emacs <file>)

	where <file> is the name of the file to be edited.
@newpage
@flushleft(@b[How to type in commands])

	Most commands in MicroEMACS are a single keystroke, or a
keystroke preceded by a command prefix.  Control commands appear in the
documentation like ^A which means to depress the <Ctrl> key and while
holding down it down, type the A character.  Meta-commands appear as
M-A which means to strike the Meta key (<ESC> on most computers) and
then after realeasing it, type the A character.  Control-X commands
usually appear as ^X-A which means to hold down the control key and type
the X character then type the A character.  Both meta commands and
control-x commands can be control characters as well, for example,
^X-^O (the delete-blank-lines command) means to hold down <Ctrl>, type
X, keep holding down <Ctrl> and type the O character.

	Many commands in MicroEMACS can be executed a number of times.
In order to make one command repeat many times, type Meta (<ESC>)
followed by a number, and then the command. for example:

@verbatim(	M 12 ^K)

	will delete 12 lines starting at the cursor and going down. 
Sometimes, the repeat count is used as an argument to the command as in
the set-tab command where the repeat count is used to set the spacing of
the tab stops. 

@flushleft(@b[The Command List])

	The following is a list of all the commands in MicroEMACS. 
Listed is the command name, the default (normal) keystrokes used to
invoke it, and alternative keys for the IBM-PC, and a description of
what the command does.

@begin(verbatim)
@b[(1) MOVING THE CURSOR]

@i(previous-page)	^Z	<Pg Up>

	Move one screen towards the begining of the file.

@i(next-page)		^V	<Pg Dn>

	Move one screen towards the end of the file.

@i(begining-of-file)	M-<	<Home>

	Place the cursor at the begining of the file.

@i(end-of-file)		M->	<End>

	Place the cursor at the end of the file.

@i(forward-character)	^F	(6 on the keypad)

	Move the cursor one character to the right.  Go down to
the begining of the next line if the cursor was already at the
end of the current line. 

@i(backward-character)	^B	(4 on the keypad)

	Move the cursor one character to the left.  Go to the
end of the previous line if the cursor was at the begining of
the current line. 

@i(next-word)		M-F	(^6 on the keypad)

	Place the cursor at the begining of the next word.

@i(previous-word)	M-B	(^4 on the keypad)

	Place the cursor at the begining of the previous word.

@i(begining-of-line)	^A

	Move cursor to the begining of the current line.

@i(end-of-line)		^E

	Move the cursor to the end of the current line.

@i(next-line)		^N	(2 on the keypad)

	Move the cursor down one line.

@i(previous-line)	^P	(8 on the keypad)

	Move the cursor up one line.

@i(goto-line)		M-G

	Goto a specific line in the file. IE    M 65 M-G    would
put the cursor on the 65th line of the current buffer.

@i(next-paragraph)	M-N

	Put the cursor at the first end of paragraph after the cursor.

@i(previous-paragraph)	M-P

	Put the cursor at the first begining of paragraph before the
cursor.

@b[(2) DELETING & INSERTING]

@i(delete-previous-character)	^H	<--

	Delete the character immedietly to the left of the
cursor.  If the cursor is at the begining of a line, this will
join the current line on the end of the previous one. 

@i(delete-next-character)	^D	<Del>

	Delete the character the cursor is on.  If the cursor is
at the end of a line, the next line is put at the end of the
current one. 

@i(delete-previous word)	M-^H	M- <--

	Delete the word before the cursor.

@i(delete-next-word)		M-^D

	Delete the word starting at the cursor.

@i(kill-to-end-of-line)

	When used with no argument, this command deletes all
text from the cursor to the end of a line.  When used on a blank
line, it deletes the blank line.  When used with an argument, it
deletes the specified number of lines. 

@i(insert-space)	^C	<Ins>

	Insert a space before the character the cursor is on.

@i(newline)		<return>

	Insert a newline into the text, move the cursor down to the
begining of the next physical line, carrying any text that was after
it with it.

@i(newline-and-indent)	^J

	Insert a newline into the text, and indent the new line the
same as the previous line.

@i(handle-tab)		^I	-->

	With no argument, move the cursor to the begining of the
next tab stop.  With an argument of zero, use real tab
characters when tabbing.  With a non-zero argument, use spaces
to tab every argument positions. 

@i(delete-blank-lines)	^X-^O

	Delete all the blank lines before and after the current cursor
position.

@i(kill-paragraph)	M-^W

	Delete the paragraph that the cursor is currently in.

@i(kill-region)		^W

	Delete all the characters from the cursor to the mark set with
the set-mark command.

@i(copy-region)

	Copy all the characters between the cursor and the mark
set with the set-mark command into the kill buffer (so they can
later be yanked elsewhere). 

@i(open-line)		^O

	Insert a newline at the cursor, but do not move the cursor.

@b[(3) SEARCHING]

@i(search-forward)	^S

	Seearch for a string from the current cursor position to
the end of the file.  The string is typed on on the bottom line of
the screen, and terminated with the <ESC> key. Special characters
can be typed in by preceeding them with a ^Q. A single ^Q
indicates a null string.  On successive searches, hitting <ESC>
alone causes the last search string to be reused.

@i(search-reverse)	^R

	This command searches backwards in the file. In all other ways
it is like search-forward.

@i(incremental-search)	^X-S

	This command is similar to forward-search, but it processes the
search as each character of the input string is typed in. This allows
the user to only use as many keystrokes as are needed to uniquely
specify the string being searched. Several control characters are active
while isearching:

	^S or ^X	Skip to the next occurence of the current string
	^R		skip to the last occurence of the current string
	^H		back up to the last match (posibly deleting
			the last character on the search string)
	^G		abort the search, return to start
	<ESC>		end the search, stay here

@i(reverse-incremental-search)	^X-R

	This command is the same as incremental-search, but it starts in
the reverse direction.

@i(hunt-forward)	unbound		(<ALT>S on the IBM PC)

	This command repeats the last search with the last search string

@i(hunt-backward)	unbound		(<ALT>R on the IBM PC)

	THe last search string is looked for starting at the cursor and
going backwards.

@b[(4) REPLACING]

@i(replace-string)	M-R

	This command allows you to replace all occurences of one string
with another string. The replacement starts at the current location of
the cursor and goes to the end of the current buffer. A numeric argument
will limit the number of strings replaced.

@i(query-replace-string)	M-^R

	Like the replace-string command, this command will replace one
string with another. However, it allows you to step through each string
and ask you if you wish to make the replacement. When the computer asks
if you wish to make the replacement, the following answers are allowed:

	Y	Make the replacement and continue on to the next string
	N	Don't make the replacement, then continue
	!	Replace the rest of the strings without asking
	^G	Stop the command
	.	Go back to place the command started
	?	get a list of options


@b[(5) CAPITALIZING & TRANSPOSING]

@i(case-word-upper)	M-U

	Change the following word into upper case.

@i(case-word-capitalize)	M-C

	Capitolize the following word.

@i(case-word-lower)	M-L

	Change the following word to lower case.

@i(case-region-upper)	^X-^U

	Change all the alphabetic characters in a marked region to upper
case.

@i(case-region-lower)	^X-^L

	Change all the alphabetic characters in a marked region to lower
case.

@i(transpose-characters)	^T

	Swap the last and second last characters behind the cursor.

@i(quote-character)	^Q

	Insert the next typed character, ignoring the fact that it may
be a command character.

@b[(6) REGIONS & THE KILL BUFFER]

@i(set-mark)	M-<SPACE>

	This command is used to delimit the begining of a marked region. 
Many commands are effective for a region of text.  A region is defined
as the text between the mark and the current cursor position.  To delete
a section of text, for example, one moves the cursor to the begining of
the text to be deleted, issues the set-mark command by typing M-<SPACE>,
moves the cursor to the end of the text to be deleted, and then deletes
it by using the kill-region (^W) command.  Only one mark can be set in
one window or one buffer at a time, and MicroEMACS will try to remember
a mark set in an offscreen buffer when it is called back on screen. 

@i(exchange-point-and-mark)	^X-^X

	This command moves the cursor to the current marked position in
the current window and moves the mark to where the cursor was.  This is
very usefull in finding where a mark was, or in returning to a position
previously marked.

@b[(7) COPYING AND MOVING]

@i(kill-region)		^W

	This command is used to copy the current region (as defined by
the current mark and the cursor) into the kill buffer.

@i(yank)		^Y

	This copies the contents of the kill buffer into the text at the
current cursor position.  This does not clear the kill buffer, and thus
may be used to make multiple copies of a section of text.

@i(copy-region)		M-W

	This command copies the contents of the current region into the
kill buffer without deleting it from the current buffer.

@b(8) MODES OF OPERATION]

@i(add-mode)		^X-M

	Add a mode to the current buffer

@i(delete-mode)		^X-^M

	Delete a mode from the current buffer

@i(add-global-mode)	M-M

	Add a mode to the global modes which get inherited by any new
buffers that are created while editing.

@i(delete-global-mode)	M-^M

	Delete a mode from the global mode list.  This mode list is
displayed as the first line in the output produced by the list-buffers
command.

@b(		MODES)

	Modes are assigned to all buffers that exist during an editing
session.  These modes effect the way text is inserted, and the operation
of some commands. Legal modes are:


@i(OVER)	Overwrite Mode

	In this mode, typed characters replace existing characters
rather than being inserted into existing lines.  Newlines still insert
themselves, but all other characters will write over existing characters
on the current line being edited.  This mode is very usefull for editing
charts, figures, and tables.

@i(WRAP)	Word Wrap Mode

	In this mode, when the cursor crosses the current fill column
(which defaults to 72) it will, at the next wordbreak, automatically
insert a newline, dragging the last word down with it.  This makes
typing prose much easier since the newline (<RETURN>) only needs to be
used between paragraphs.

@i(VIEW)	File Viewing Mode

	In this mode, no commands which can change the text are allowed.

@i(CMODE)	C Program Editing Mode

	This mode is for editing programs written in the 'C' programming
language.  When the newline is used, the editor will attempt to place
the cursor at the proper indentation level on the next line.  Close
braces are automatically undented for the user, and also pre-processor
commands are automatically set flush with the left margin.  When a close
parenthesis or brace is typed, if the matching open is on screen, the
cursor briefly moves to it, and then back. (Typing any key will abort
this fence matching, executing the next command immediatly)

@i(EXACT)	Exact Case Matching on Searching MODE

	Normally case is insignificant during the various search
commands.  This forces all matching to take character case into account.

@i(MAGIC)	Regular expresion pattern matching Mode

	This feature is not yet implimented.  While it may be set as a
mode, it will have no effect at the moment.  When it is ready, it will
cause all search commands to accept various pattern characters to allow
regular exspression search and replaces.

@b[(10) ON-SCREEN FORMATTING]

@i(set-fill-column)	^X-F

	Sets the column used by WRAP mode and the fill-paragraph command.

@i(handle-tab)		<TAB>

	Given a numeric argument, the tab key resets the normal behavior
of the tab key.  An argument of zero causes the tab key to generate
hardware tabs (at each 8 columns).  A non-zero argument will cause the
tab key to generate enough spaces to reach a culumn of a multiple of the
argument given.  This also resets the spacing used while in CMODE.

@i(fill-paragraph)	M-Q

	This takes all the text in the current paragraph (as defined by
surrounding blank lines, or a leading indent) and attempt to fill it
from the left margin to the current fill column.

@i(buffer-position)

	This command reports on the current and total lines and
characters of the current buffer.  It also gives the hexidecimal code of
the character currently under the cursor.

@b[(11) MULTIPLE WINDOWS]

@i(split-current-window)	^X-2

	If possible, this command splits the current window into two
near equal windows, each displaying the buffer displayed by the original
window. A numeric argument of 1 forces the upper window to be the new
current window, and an argument of 2 forces the lower window to be the
new current window.

@i(delete-window)		^X-0

	this command attempts to delete the current window, retrieving
the lines for use in the window above or below it.

@i(delete-other-windows)	^X-1

	All other windows are deleted by this command.  The current
window becomes the only window, using the entire availible screen.

@i(next-window)		^X-O

	Make the next window down the current window.  With an argument,
this makes the nth window from the top current.

@i(previous-window)	^X-P

	Make the next window up the current window.  With an argument,
this makes tghe nth window from the bottom the current window.

@i(scroll-next-down)	M-^V

	Scroll the next window down a page.

@i(scroll-next-up)	M-^Z

	Scroll the next window up a page.

@b[(12) CONTROLLING WINDOWS]

@i(grow-window)		^X-^

	Enlarge the current window by the argument number of lines (1 by
default).

@i(shrink-window)	^X-^Z

	Shrink the current window by the argument number of lines (1 by
default).

@i(resize-window)	^X-W

	CHnage the size of the current window to the number of lines
specified by the argument, if possible.

@i(move-window-down)	^X-^N

	Move the window into the current buffer down by one line.

@i(move-window-up)	^X-^P

	Move the window into the current buffer up by one line.

@i(redraw-display)	M-^L

	Redraw the current window with the current line in the middle of
the window, of with an argument, with the current line on the nth line
of the current window.

@i(clear-and-redraw)	^L

	Clear the screen and redraw the entire display.  Usefull on
timesharing systems where messages and other things can garbage the display.

@b[(13) MULTIPLE BUFFERS]

@i(select-buffer)	^X-B

	Switch to using another buffer in the current window.  MicroEMACS
will prompt you for the name of the buffer to use.

@i(next-buffer)		^X-X

	Switch to using the next buffer in the buffer list in the
current window.

@i(name-buffer)		M-^N

	Change the name of the current buffer.

@i(kill-buffer)		^X-K

	Dispose of an undisplayed buffer in the editor and reclaim the
space. This does not delete the file the buffer was read from.

@i(list-buffers)	^X-^B

	Split the current window and in one half bring up a list of all
the buffers currently existing in the editor.  The active modes, change
flag, and active flag for each buffer is also displayed.  (The change
flag is an * if the buffer has been changed and not written out.  the
active flag is not an * if the file had been specified on the command
line, but has not been read in yet since nothing has switched to that
buffer.)

@i[(14) READING FROM DISK]

@i(find-file)		^X-^F

	FInd the named file. If it is already in a buffer, make that
buffer active in the current window, otherwise attemt tocreate a new
buffer and read the file into it.

@i(read-file)		^X-^R

	Read the named file into the current buffer (overwriting the
previous contents of the current buffer. If the change flag is set, a
confirmation will be asked).

@i(insert-file)		^X-^I

	Insert the named file into the current position of the current
buffer.

@i(view-file)		^X-^V

	Like find-file, this command either finds the file in a buffer,
or creates a new buffer and reads the file in. In addition, this leaves
that buffer in VIEW mode.

@i[(15) SAVING TO DISK]

@i(save-file)		^X-^S

	If the contents of the current buffer have been changed, write
it back to the file it was read from.

@i(write-file)		^X-^W

	Write the contents of the current file to the named file, this
also changed the file name associated with the current buffer to the new
file name.

@i(change-file-name)	^X-N

	Change the name associated with the current buffer to the file
name given.

@i(quick-exit)		M-Z

	Write out all changed buffers to the files they were read from
and exit the editor.

@b[(16) ACCESSING THE OPERATING SYSTEM]

@i(shell-command)	^X-!

	Send one command to execute to the operating system command
processor, or shell.  Upon completion, MicroEMACS will wait for a
keystroke to redraw the screen. 

@i(pipe-command)	^X-@

	Execute one operating system command and pipe the resulting
output into a buffer by the name of "command".

@i(filter-buffer)	^X-#

	Execute one operating system command, using the contents of the
current buffer as input, and sending the results back to the same
buffer, replacing the original text.

@i(i-shell)		^X-C

	Push up to a new command processor or shell.  Upon exiting the
shell, MicroEMACS will redraw its screen and continue editing.

@i(suspend-emacs)	^X-D		[only under BSD4.2]

	This command suspends the editing processor and puts it into the
background.  The "fg" command will restart MicroEMACS.

@i(exit-emacs)		^X-^C

	Exit MicroEMACS back to the operating system.  If there are any
unwritten, changed buffers, the editor will promt to discard changes.

@b[(17) KEY BINDINGS AND COMMANDS]

@i(bind-to-key)		M-K

	This command takes one of the named commands and binds it to a
key.  From then on, whenever that key is struck, the bound command is
executed.

@i(unbind-key)		M-^K

	This unbinds a command from a key.

@i(describe-key)	^X-?

	This command will allow you to type a key and it will then
report the name of the command bound to that key.

@i(execute-named-command)	M-X

	This command will prompt you for the name of a command to
execute.  Typing <SPACE> part way thought will tell the editor to
attempt to complete the name on its own.  If it then beeps, there is no
such command to complete.

@i(describe-bindings)		UNBOUND

	This command splits the current window, and in one of the
windows makes a list of all the named commands, and the keys currently
bound to them.

@b[(18) COMMAND EXECUTION]

	Commands can also be executed as command scripts.  This allows
comands and their arguments to be stored in files and executed.  The
general form of a command script line is:

	<optional repeat count> {command-name} <optional arguments>

@i(execute-command-line)	UNBOUND

	Execute a typed in script line.

@i(execute-buffer)		UNBOUND

	Executes script lines in the named buffer.  If the buffer is off
screen and an error occurs during execution, the cursor will be left on
the line causing the error.

@i(execute-file)		UNBOUND

	Executes script lines from a file.  This is the normal way to
execute a special script.

@i(clear-message-line)		UNBOUND

	Clears the message line during script execution.  This is
usefull so as not to leave a confusion message from the last commands
in a script.

@i(unmark-buffer)		UNBOUND

	Remove the change flag from the current buffer.  This is very
usefull in scripts where you are creating help windows, and don't want
MicroEMACS to complain about not saving them to a file.

@i(insert-string)		UNBOUND

	Insert a string into the current buffer.  This allows you to
build up text within a buffer without reading it in from a file.  Some
special characters are allowd, as follows:

	~n	newline
	~t	tab
	~b	backspace
	~f	formfeed


@b[(19) MACRO EXECUTION]

	Also availible is one keyboard macro, which allows you to record
a number of commands as they are executed and play them back.

@i(begin-macro)		^X (

	Start recording keyboard macro

@i(end-macro)		^X )

	Stop recording keyboard macro

@i(execute-macro)	^X E

	Execute keyboard macro

@i(store-macro)		UNBOUND

	This command is used to store script lines in a hiffen buffer by
the name of "[Macro nn]" where <nn> is a number from 1 to 40 and
coresponds to the argument given this command.  All script lines then
encountered will be stored in this buffer rather than being executed.  A
script line consisting of only "[end]" tells the editor that the macro
is complete, and stops recording script lines in the buffer.

@i(execute-macro-nn)	UNBOUND		[shift-<F1> thru shift-<F10>]

	This is the command to execute a script stored in one of the
hidden macro buffers.  On the IBM-PC the first ten of these are bound to
shift-<F1> thru shift-<F10>.
@end(verbatim)
