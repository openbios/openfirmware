SIMTTY = /dev/pts/1

OS := $(shell uname)

# XXX need a better way of determining this
HOST := x86

HOSTDIR := $(shell eval "(cd ../../${HOST}/${OS}; pwd)")

all: kernel.hex

.PHONY: FORCE all clean

.PRECIOUS: kernel.img

${HOSTDIR}/forth:
	@make -C ${HOSTDIR} forth

sim:  kernel.hex
	s51 -s ${SIMTTY} -X 32M kernel.hex

build: ${HOSTDIR}/forth
	@ln -sf ${HOSTDIR}/forth $@

%.img: FORCE build
	HOSTDIR=${HOSTDIR} ./build $@

%.hex: %.img
	objcopy -I binary -O ihex $< $@

clean:
	rm -f *.img *.hex *.log headers *~ build
