/*	Machine/OS definitions			*/

#define OFW     1                       /* Open Boot Prom               */
#define AMIGA   0                       /* AmigaDOS			*/
#define ST520   0                       /* ST520, TOS                   */
#define MSDOS   0                       /* MS-DOS                       */
#define V7      0                       /* V7 UN*X or Coherent or BSD4.2*/
#define	BSD	0			/* UNIX BSD 4.2	and ULTRIX	*/
#define	USG	0			/* UNIX system V		*/
#define VMS     0                       /* VAX/VMS                      */
#define CPM     0                       /* CP/M-86                      */

/*	Compiler definitions			*/
#define	GCC	1	/* Gnu C Compiler */
#define MWC86   0	/* marc williams compiler */
#define	LATTICE	0	/* either lattice compiler */
#define	LAT2	0	/* Lattice 2.15 */
#define	LAT3	0	/* Lattice 3.0 */
#define	AZTEC	0	/* Aztec C 3.20e */
#define	MSC	0	/* MicroSoft C compile version 3 */

/*	Profiling options	*/
#define	APROF	0	/* turn Aztec C profiling on? */
#define	NBUCK	100	/* number of buckets to profile */

/*   Special keyboard definitions            */
 
#define WANGPC	0			/* WangPC - mostly escape sequences     */
 
/*	Terminal Output definitions		*/

#define ANSI    1			/* ansi escape sequences	*/
#define	HP150	0			/* HP150 screen driver		*/
#define	VMSVT	0			/* various VMS terminal entries	*/
#define VT52    0                       /* VT52 terminal (Zenith).      */
#define VT100   0                       /* Handle VT100 style keypad.   */
#define LK201   0                       /* Handle LK201 style keypad.   */
#define RAINBOW 0                       /* Use Rainbow fast video.      */
#define TERMCAP 0                       /* Use TERMCAP                  */
#define	IBMPC	0			/* IBM-PC specific driver	*/
#define	DG10	0			/* Data General system/10	*/

/*	Configuration options	*/

#define CVMVAS  1	/* arguments to page forward/back in pages	*/
#define	NFWORD	0	/* forward word jumps to begining of word	*/
#define	CLRMSG	0	/* space clears the message line with no insert	*/
#define	TYPEAH	1	/* type ahead causes update to be skipped	*/
#define	FILOCK	0	/* file locking under unix BSD 4.2		*/
#define	REVSTA	0	/* Status line appears in reverse video		*/
#define	COLOR	1	/* color commands and windows			*/
#define	ACMODE	1	/* auto CMODE on .C and .H files		*/
#define	CFENCE	1	/* fench matching in CMODE			*/
#define	ISRCH	1	/* Incremental searches like ITS EMACS		*/
#define	WORDPRO	1	/* Advanced word processing features		*/
