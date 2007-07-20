SIMTTY = /dev/pts/1

OS := $(shell uname)

# XXX need a better way of determining this
HOST := x86

XHOSTDIR := $(shell eval "(cd ../../${HOST}/${OS}; pwd)")

all: kernel.hex

.PHONY: FORCE all clean

.PRECIOUS: kernel.img

${XHOSTDIR}/forth:
	@make -C ${XHOSTDIR} forth

sim:  kernel.hex
	s51 -s ${SIMTTY} -X 32M /c/Temp/kernel.hex

build: ${XHOSTDIR}/forth
	@ln -sf ${XHOSTDIR}/forth $@

%.img: FORCE build
	./build $@

%.hex: %.img
	objcopy -I binary -O ihex $< $@

clean:
	rm -f *.img *.hex *.log headers *~ build
