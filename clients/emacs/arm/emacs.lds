OUTPUT_FORMAT("elf32-littlearm");
OUTPUT_ARCH(ARM);

ENTRY(_start); 
SECTIONS {
	. = 0x100000;
	.text : {
		*(.text)
	}
	.rodata : {
		*(.rodata*)
	}
	.data : {
		*(.data)
	}
}
