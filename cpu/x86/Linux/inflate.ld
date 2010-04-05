SECTIONS
{
  . = 0x00000;
  .text : { *(.text_inflate) }
  .text_spare : { *(.text) }
}

