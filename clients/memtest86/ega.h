#ifndef EGA_H
#define EGA_H

#ifdef EMULATE_EGA

void ega_init(void);
void set_ega_char(int y, int x, char ch);
void set_ega_color(int y, int x, char color);
void set_ega_char_color(int y, int x, char ch, char color);
char get_ega_char(int y, int x);
char get_ega_color(int y, int x);

#else
#define SCREEN_ADR	0xb8000
#define SCREEN_END_ADR  (SCREEN_ADR + 80*25*2)

#define EGA_ADR(y, x, offset)  *(char *)(SCREEN_ADR + (y * 160) + (x * 2) + offset)

#define ega_init()  do { } while(0)
#define set_ega_char(y, x, ch)  EGA_ADR(y, x, 0) = (ch)
#define set_ega_color(y, x, color)  EGA_ADR(y, x, 1) = (color)
#define set_ega_char_color(y, x, ch, color)  set_ega_char(y, x, ch); set_ega_color(y, x, color)
#define get_ega_char(y, x) EGA_ADR(y, x, 0)
#define get_ega_color(y, x) EGA_ADR(y, x, 1)

#endif /* EMULATE_EGA */

#endif /* EGA_H */
