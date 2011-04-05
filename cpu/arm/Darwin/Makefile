# Darwin ARM tools

BP = ../../..
ZIPDIR = ${BP}/forth/wrapper/zip

# Rationale for these flags:
#   -Oz optimizes for smallest possible size. (Apple-specific)
#   -fno-toplevel-reorder keeps inflate() as the first entry point.
#   -thumb gives 30%-50% improvement over ARM32. 
#   -arch armv7 uses more powerful instructions for less space.
#   -static -nostartfiles allows us to link this as a static text image.
# This set of flags generates an inflate.bin of 3546 bytes.

CFLAGS = -Oz -arch armv7 -mthumb -static -nostartfiles -fno-toplevel-reorder

INFLATEBIN = ../build/inflate.bin

$(INFLATEBIN): inflate
	segedit $< -extract __TEXT __text $@

inflate: ${ZIPDIR}/inflate.c
	${CC} ${CFLAGS} -o $@ $<

clean:
	rm -f *.o inflate $(INFLATEBIN)
