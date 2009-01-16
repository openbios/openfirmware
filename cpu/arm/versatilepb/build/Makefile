OS := $(shell uname)

BASEDIR= `(cd ../../../..; pwd;)`
TAGFILES= ../../build/*.tag *.tag
CLIENTDIR=../../../../clients
CLIENTPROGS=

all: qemubase.rom tags

qemubase.tag: qemubase.rom

tags: qemubase.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

qemubase.rom: FORCE build ${CLIENTPROGS}
	./build $@

../../${OS}/forth:
	@make -C ../../${OS} forth

../../build/inflate.bin:
	@make -C ../../build inflate.bin

build: ../../${OS}/forth
	@ln -sf ../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.rom *.version

clean-all: clean
	@make -C ../../build clean
	@make -C ../../${OS} clean

.PHONY: FORCE clean all clean-all
