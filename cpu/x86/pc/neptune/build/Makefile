OS := $(shell uname)

all: neptune.rom

neptune.rom: FORCE build ../../../build/inflate.bin ../../../../../clients/memtest86/memtest
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

../../../../../clients/memtest86/memtest:
	@make -C ../../../../../clients/memtest86 memtest

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build neptune.rom

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean
	@make -C ../../../../../clients/memtest86 clean

.PHONY: FORCE clean all clean-all
