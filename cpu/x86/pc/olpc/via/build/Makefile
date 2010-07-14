OS := $(shell uname)

CPUDIR=../../../..
BASEDIR := $(shell cd ${CPUDIR}/../..; pwd;)
TAGFILES= ${CPUDIR}/build/*.tag *.tag
CLIENTDIR=${BASEDIR}/clients
CLIENTPROGS=memtest ${CLIENTDIR}/emacs/x86/emacs

all: olpc.rom tags

fw.tag: olpc.rom

tags: fw.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

ofw.elf: FORCE build ${CPUDIR}/build/inflate.bin
	./build $@

olpc.rom: FORCE build ${CPUDIR}/build/inflate.bin ${CLIENTPROGS}
	./build $@

${CPUDIR}/${OS}/forth:
	@make -C ${CPUDIR}/${OS} forth

${CPUDIR}/build/inflate.bin:
	@make -C ${CPUDIR}/build inflate.bin

memtest:
	make -C ${CLIENTDIR}/memtest86 VARIANT=OLPCVIA memtest
	@mv ${CLIENTDIR}/memtest86/memtest .
	@make -C ${CLIENTDIR}/memtest86 clean

${CLIENTDIR}/emacs/x86/emacs:
	@make -C ${CLIENTDIR}/emacs/x86 emacs

build: ${CPUDIR}/${OS}/forth
	@ln -sf ${CPUDIR}/${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.rom *.version *.bin *.tag tags

clean-all: clean
	@make -C ${CPUDIR}/build clean
	@make -C ${CPUDIR}/${OS} clean

.PHONY: FORCE clean all clean-all
