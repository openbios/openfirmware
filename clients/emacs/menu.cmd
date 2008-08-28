;	MENU.CMD:	Menu learning system for MicroEMACS 3.7
;
;			This file is executed to activate MicroEMACS's
;			menu interface code

;	setup windows for use

	add-global-mode "blue"
	1 split-current-window
	5 resize-window
	add-mode "red"
	view-file "menu1"
	name-buffer "menu window"
	change-file-name ""
	add-mode "view"
	next-window

;	Load menu routines as needed

;	Activate Main Menu

1	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<01"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key execute-macro-3	FN;
	bind-to-key execute-macro-4	FN<
	bind-to-key execute-macro-5	FN=
	bind-to-key execute-macro-6	FN>
	bind-to-key execute-macro-7	FN?
	bind-to-key execute-macro-8	FN@
	bind-to-key execute-macro-9	FNA
	bind-to-key execute-macro-2	FNB
	bind-to-key execute-macro-10	FNC
	bind-to-key exit-emacs		FND
	clear-message-line
[end]

;	and bring that menu up

	execute-macro-1
	write-message "         [loading MENU system]"

;	set up the editor control menu

2	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<02"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key execute-macro-11	FN;
	bind-to-key execute-macro-12	FN<
	bind-to-key execute-macro-13	FN=
	bind-to-key execute-macro-14	FN>
	bind-to-key execute-macro-15	FN?
	bind-to-key execute-macro-16	FN@
	bind-to-key execute-macro-17	FNA
	bind-to-key execute-macro-18	FNB
	bind-to-key execute-macro-19	FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate word case/screen control Menu

3	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<03"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key case-word-upper	FN;
	bind-to-key case-region-upper	FN<
	bind-to-key case-word-lower	FN=
	bind-to-key case-region-lower	FN>
	bind-to-key case-word-capitalize FN?
	unbind-key FN@
	bind-to-key clear-and-redraw	FNA
	bind-to-key set-mark		FNB
	bind-to-key redraw-display	FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate paging/scrolling Menu

4	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<08"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key previous-page	FN;
	bind-to-key next-page		FN<
	bind-to-key move-window-down	FN=
	bind-to-key move-window-up	FN>
	bind-to-key scroll-next-up	FN?
	unbind-key 			FN@
	bind-to-key scroll-next-down	FNA
	unbind-key 			FNB
	bind-to-key exchange-point-and-mark FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate cut & paste Menu

5	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<04"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key set-mark		FN;
	unbind-key FN<
	bind-to-key kill-region		FN=
	unbind-key FN>
	bind-to-key copy-region		FN?
	unbind-key FN@
	bind-to-key yank		FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate Search & replace Menu

6	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<09"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key search-forward	FN;
	bind-to-key search-reverse	FN<
	bind-to-key hunt-forward	FN=
	bind-to-key hunt-backward	FN>
	bind-to-key incremental-search	FN?
	bind-to-key reverse-incremental-search FN@
	bind-to-key replace-string	FNA
	bind-to-key query-replace-string FNB
	unbind-key FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate Deletion Menu

7	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<05"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key delete-previous-character FN;
	unbind-key FN<
	bind-to-key delete-next-character FN=
	unbind-key FN>
	bind-to-key kill-to-end-of-line	FN?
	unbind-key FN@
	bind-to-key delete-blank-lines	FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate Word procesing Menu

8	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<10"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key previous-word	FN;
	bind-to-key next-word		FN<
	bind-to-key previous-paragraph	FN=
	bind-to-key next-paragraph	FN>
	bind-to-key fill-paragraph	FN?
	bind-to-key kill-paragraph	FN@
	bind-to-key delete-previous-word FNA
	bind-to-key delete-next-word	FNB
	bind-to-key count-words		FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate Insertion Menu

9	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<06"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key open-line		FN;
	bind-to-key insert-string	FN<
	bind-to-key handle-tab		FN=
	bind-to-key quote-character	FN>
	bind-to-key insert-space	FN?
	bind-to-key transpose-characters FN@
	bind-to-key newline-and-indent	FNA
	unbind-key FNB
	bind-to-key newline		FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

;	Activate Cursor movement Menu

10	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<07"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key begining-of-file	FN;
	bind-to-key previous-line	FN<
	bind-to-key backward-character	FN=
	bind-to-key forward-character	FN>
	bind-to-key end-of-file		FN?
	bind-to-key next-line		FN@
	bind-to-key begining-of-line	FNA
	bind-to-key end-of-line		FNB
	bind-to-key execute-macro-21	FNC
	bind-to-key execute-macro-1	FND
	clear-message-line
[end]

21	store-macro
	"@Line number to go to: " goto-line
[end]

;	Activate Buffer Menu

11	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<11"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key buffer-position	FN;
	bind-to-key unmark-buffer	FN<
	bind-to-key delete-buffer	FN=
	bind-to-key next-buffer		FN>
	bind-to-key list-buffers	FN?
	bind-to-key execute-macro-22	FN@
	bind-to-key name-buffer		FNA
	unbind-key FNB
	bind-to-key select-buffer	FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

22	store-macro
	filter-buffer "@Name of DOS filter: "
[end]
;	Macro Menu

12	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<11"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key begin-macro		FN;
	unbind-key FN<
	bind-to-key end-macro		FN=
	unbind-key FN>
	bind-to-key execute-macro	FN?
	unbind-key FN@
	unbind-key FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	Color change Menu

13	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<12"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key execute-macro-23	FN;
	unbind-key FN<
	bind-to-key execute-macro-24	FN=
	unbind-key FN>
	bind-to-key execute-macro-25	FN?
	unbind-key FN@
	bind-to-key execute-macro-26	FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	Set forground color

23	store-macro
	save-window
	1 next-window
	select-buffer "[color]"
	begining-of-file
	insert-string "@Color to change to: "
	newline
	begining-of-file
	case-word-upper
	begining-of-file
	unmark-buffer
	select-buffer "menu window"
	1 redraw-display
	restore-window
	add-mode "#[color]"
	delete-buffer "[color]"
[end]

;	Set background color

24	store-macro
	save-window
	1 next-window
	select-buffer "[color]"
	begining-of-file
	insert-string "@Color to change to: "
	newline
	begining-of-file
	case-word-lower
	begining-of-file
	unmark-buffer
	select-buffer "menu window"
	1 redraw-display
	restore-window
	add-mode "#[color]"
	delete-buffer "[color]"
[end]

;	Set global forground color

25	store-macro
	save-window
	1 next-window
	select-buffer "[color]"
	begining-of-file
	insert-string "@Color to change to: "
	newline
	begining-of-file
	case-word-upper
	begining-of-file
	unmark-buffer
	select-buffer "menu window"
	1 redraw-display
	restore-window
	add-global-mode "#[color]"
	delete-buffer "[color]"
[end]

;	Set global background color

26	store-macro
	save-window
	1 next-window
	select-buffer "[color]"
	begining-of-file
	insert-string "@Color to change to: "
	newline
	begining-of-file
	case-word-lower
	begining-of-file
	unmark-buffer
	select-buffer "menu window"
	1 redraw-display
	restore-window
	add-global-mode "#[color]"
	delete-buffer "[color]"
[end]

;	set Mode Menu

14	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<17"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key add-mode		FN;
	bind-to-key add-global-mode	FN<
	bind-to-key delete-mode		FN=
	bind-to-key delete-global-mode	FN>
	unbind-key FN?
	bind-to-key execute-macro-27	FN@
	unbind-key FNA
	unbind-key FNB
	bind-to-key select-buffer	FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

27	store-macro
	"@Column to fill to: " set-fill-column
[end]

;	DOS command Menu

15	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<13"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key shell-command	FN;
	unbind-key FN<
	bind-to-key pipe-command	FN=
	unbind-key FN>
	bind-to-key i-shell		FN?
	unbind-key FN@
	bind-to-key quick-exit		FNA
	unbind-key FNB
	bind-to-key exit-emacs		FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	Script Menu

16	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<18"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key execute-file	FN;
	bind-to-key execute-command-line FN<
	bind-to-key execute-buffer	FN=
	bind-to-key execute-named-command FN>
	unbind-key FN?
	unbind-key FN@
	unbind-key FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	File access Menu

17	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<14"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key find-file		FN;
	bind-to-key save-file		FN<
	bind-to-key view-file		FN=
	bind-to-key write-file		FN>
	bind-to-key read-file		FN?
	bind-to-key change-file-name	FN@
	bind-to-key insert-file		FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	Window Menu

18	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<19"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key split-current-window FN;
	bind-to-key delete-other-windows FN<
	bind-to-key resize-window	FN=
	bind-to-key delete-window	FN>
	bind-to-key shrink-window	FN?
	bind-to-key grow-window		FN@
	bind-to-key next-window		FNA
	bind-to-key previous-window	FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

;	key binding Menu

19	store-macro
	save-window
	1 next-window
	begining-of-file
	search-forward "<<15"
	next-line
	1 redraw-display
	restore-window
	update-screen

;	***** Rebind the Function key group

	bind-to-key bind-to-key		FN;
	unbind-key FN<
	bind-to-key unbind-key		FN=
	unbind-key FN>
	bind-to-key describe-key	FN?
	unbind-key FN@
	bind-to-key describe-bindings	FNA
	unbind-key FNB
	unbind-key FNC
	bind-to-key execute-macro-2	FND
	clear-message-line
[end]

	clear-message-line
