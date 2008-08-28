/*	PATH:	This file contains certain info needed to locate the
		MicroEMACS files on a system dependant basis.

									*/

/*	possible names and paths of help files under different OSs	*/

char *pathname[] =

#if	OFW
{
	"emacs.rc",
	"emacs.hlp",
	"",
	"/disk:\\",
        "rom:"
};
#endif

#if	AMIGA
{
	".emacsrc",
	"emacs.hlp",
	"",
	":c/",
	":t/"
};
#endif

#if	MSDOS
{
	"emacs.rc",
	"emacs.hlp",
	"",
	"\\",
	"\\bin\\",
	"\\fm\\emacs\\",
	"c:\\fm\\emacs\\"
};
#endif

#if	V7 | BSD | USG
{
	".emacsrc",
	"emacs.hlp",
	"/usr/local/",
	"/usr/lib/",
	""
};
#endif

#if	VMS
{
	"emacs.rc",
	"emacs.hlp",
	"",
	"sys$sysdevice:[vmstools]"
};
#endif

#define	NPNAMES	(sizeof(pathname)/sizeof(char *))
