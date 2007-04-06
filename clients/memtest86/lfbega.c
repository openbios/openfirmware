/* EGA Emulator
 *
 * Released under version 2 of the Gnu Public License.
 * By Lilian Walter
 */

#include "screen_buffer.h"
#include "ega.h"
#include "lfbgeometry.h"
#include "font_sun12x22.h"

#define abs(x) ( (x>=0) ? x : -x)

#define bswap32(x) ( ((( x >> 24) & 0xff) << 0) | \
		     ((( x >> 16) & 0xff) << 8) | \
		     ((( x >>  8) & 0xff) << 16) | \
		     ((( x >>  0) & 0xff) << 24) )

// ega_buf replaces SCREEN_ADR
//
// 2 bytes per char:
//   0: char
//   1: bits:
//           7: blink
//        6..4: background color
//           3: intensity
//        2..0: foreground color
//
// 0=black; 1=blue; 2=green; 3=cyan; 4=red; 5=magenta; 6=brown; 7=white

static char ega_buf[80*25*2];

extern unsigned int lfb_addr(void);
static unsigned int fbadr;
static int font_adr;                   // Start of font data

static int window_top;                 // Number of pixels to top of window
static int window_left;                // Number of pixels to left of window

// All places that write to SCREEN_ADR must be translated into write to
// ega_buf AND perform ega emulation (include colors).  Set color byte
// before char byte.

// set-font  ( font-base char-width char-height fontbytes min-char #glyphs -- )
// If char-height is positive, then we use the original packed font
// storage format in which the last scan line of one glyph overlaps
// the first scan line of the next.  If +-height is negative, we
// use an unpacked format in which each glyph is self-contained.

// Font file format:
//   words      content (big endian)
//     0        "font"
//     4        0x0c: char-width
//     8        0x16: char-height, if positive, glyph-bytes=char-height-1*fontbytes
//                                   else glyph-bytes=abs(char-height)
//     c        0x02: fontbytes
//    10        0x20: min-char (first char)
//    14        0xe0: #glyphs  (# of chars)
//    28        font-base: beginning of font data

// : bytes/line16 ( -- n ) d# 1200 2* ;
// : screen-adr16 ( column# line# -- adr )
//    char-height * window-top + swap char-width 2* * window-left + swap
//    bytes/line16 * + frame-buffer-adr +
// ;
// : cursor-adr16 ( -- adr ) column# line# screen-adr16  ;
// : >font ( char -- adr ) min-char - 0 max #glyphs min glyph-bytes * font-base + ;
// : fb16-draw-character ( char -- )
//    >font fontbytes char-width char-height cursor-adr16 bytes/line16
//    text-foreground16 text-background16 fb16-paint
// ;
// : fb16-paint ( fontadr fontbytes width height screenadr bytes/line fg bg -- )
//    for each bit, if 1, set 16-bit pixel to fg-color else bg-color
// ;

// 16 bits/pixel


char *get_glyph (char ch)
{
  return (char *)(font_adr+((int)ch - first_char)*glyph_bytes);
}

void display_ch (int y, int x, char ch, unsigned short fg, unsigned short bg)
{
  char *fadr;
  unsigned short *fb, c;
  int i, j, k;

  // Find glyph address for ch
  fadr = get_glyph (ch);

  // for each bit in glyph, set pixel to either fg or bg
  for (i=0; i<char_height; i++)
  {
    fb =  (unsigned short *)(fbadr +
			     ( ((y * char_height) + i + window_top) * screen_width +
			       (x * char_width + window_left)) * pixel_bytes );

    for (j=0; j<char_width; j++)
    {
      k = (fadr[j>>3] >> (7-(j&7))) & 1;
      if (k==1) c = fg; else c = bg;
      *fb = c;  fb++;
    }
    fadr += font_bytes;
  }
}

unsigned short ega_565[16] = {
  // black blue     green    cyan     red      magenta  brown    light-gray
  0x0000U, 0x0015U, 0x0540U, 0x0555U, 0xa800U, 0xa815U, 0xaab5U, 0xad55U,
  // dark-gray brite-blue brite-green brite-cyan brite-red brite-magenta yellow   white
  0x52aaU,     0x52bfU,   0x57eaU,    0x57ffU,   0xfaaaU,  0xfabfU,      0xffeaU, 0xffffU,
};

void ega_color_fg_bg (char color, unsigned short *fg, unsigned short *bg)
{
  *fg = ega_565[color & 0x0f];
  *bg = ega_565[(color>>4) & 7];
}

char get_ega_char  (int y, int x)
{
  return ega_buf[(y*80+x)*2];
}

char get_ega_color  (int y, int x)
{
  return ega_buf[(y*80+x)*2+1];
}

void set_ega_char  (int y, int x, char ch)
{
  unsigned short fg, bg;
  ega_buf[(y*80+x)*2] = ch;
  ega_color_fg_bg (get_ega_color(y,x), &fg, &bg);
  display_ch (y, x, ch, fg, bg);
}

void set_ega_color  (int y, int x, char color)
{
  unsigned short fg, bg;
  ega_buf[(y*80+x)*2+1] = color;
  ega_color_fg_bg (color, &fg, &bg);
  display_ch (y, x, get_ega_char(y,x), fg, bg);
}

void set_ega_char_color  (int y, int x, char ch, char color)
{
  unsigned short fg, bg;
  ega_buf[(y*80+x)*2] = ch;
  ega_buf[(y*80+x)*2+1] = color;
  ega_color_fg_bg (color, &fg, &bg);
  display_ch (y, x, ch, fg, bg);
}

// OLPC specific
void ega_init  ()
{
//  int i, result;
  int i;
  unsigned short *fb;

  /* Zero the EGA buffer */
  for (i=0; i<sizeof(ega_buf); i++) ega_buf[i] = 0;

  /* OLPC display controller: assume OFW has mapped virt=phys already */
//  result = pci_conf_read(0, 1, 1, 0x10, 4, &fbadr);
  fbadr = lfb_addr();

  /* Initialize variables about font */
  font_adr = (int)&fontdata_sun12x22; 

  window_top = (screen_height - (char_height*25)) / 2;
  window_left = (screen_width - (char_width*80)) / 2;

  // Black out entire screen
  fb = (unsigned short *)fbadr;
  for (i=0; i<(screen_width*screen_height); i++)
  {
    *fb = ega_565[0];  fb++;
  } 
}
