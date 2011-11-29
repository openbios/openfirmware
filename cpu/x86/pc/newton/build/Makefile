OS := $(shell uname)

CPUDIR=../../..
BASEDIR := $(shell cd ${CPUDIR}/../..; pwd;)
TAGFILES= ${CPUDIR}/build/*.tag *.tag
CLIENTDIR=${BASEDIR}/clients
CLIENTPROGS=

all: ofw.elf tags

fw.tag: ofw.elf

tags: fw.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

ofw.elf: FORCE build ../../../build/inflate.bin ${CLIENTPROGS}
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.rom *.version *.bin *.tag tags

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean

.PHONY: FORCE clean all clean-all
