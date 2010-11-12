OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
SECTIONS
{
  . = 0x00000;
  .text : { *(.text_inflate) }
  .text_spare : { *(.text) }
}
