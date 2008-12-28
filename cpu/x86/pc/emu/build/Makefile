OS := $(shell uname)

all: emuofw.rom

emuofw.rom: FORCE build ../../../build/inflate.bin
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.c32 *.rom

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean

.PHONY: FORCE clean all clean-all
