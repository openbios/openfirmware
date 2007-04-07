/* config.h - MemTest-86  Version 3.3
 *
 * Compile time configuration options
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady
 */

/* PARITY_MEM - Enables support for reporting memory parity errors */
/*	Experimental, normally enabled */
#define PARITY_MEM

/* SERIAL_CONSOLE_DEFAULT -  The default state of the serial console. */
/*	This is normally off since it slows down testing.  Change to a 1 */
/*	to enable. */
#define SERIAL_CONSOLE_DEFAULT 0

/* SERIAL_BAUD_RATE - Baud rate for the serial console
 * If this is not defined it is assumed a previous program has set the
 * baud rate, and the baud rate is preserved.
 */
/* 
#define SERIAL_BAUD_RATE 9600
*/

/* SCRN_DEBUG - extra check for SCREEN_BUFFER
 */ 
/* #define SCRN_DEBUG */

/* APM - Turns off APM at boot time to avoid blanking the screen */
/*	Normally enabled */
#define APM_OFF

/* USB_WAR - Enables a workaround for errors caused by BIOS USB keyboard */
/*	and mouse support*/
/*	Normally enabled */
#define USB_WAR

/* EMULATE_EGA - Enables EGA emulation instead of writing to EGA buffer directly */
/*      Normally not enabled */
/*      Enabled for OLPC */
#define EMULATE_EGA

/* OLPC - uses OLPC hardware instead of BIOS */
/*      Normally not enabled */
/*      Enabled for OLPC */
#define OLPC
