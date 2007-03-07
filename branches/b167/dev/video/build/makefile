all: video.fc
	@true

SRCS= ../common/*.fth ../dacs/*.fth ../controlr/*.fth

include ${BP}/default.mk

video.fc: loadfcod.fth ${SRCS}
	${WRAPPER} ${TOKENIZER} -s "tokenize loadfcod.fth $@"
	
clean:
	rm -f *.fc

RELDIR=/fw/release
PARTNO=631-0000-2300010-01
REV=A

release:
	mkdir  ${RELDIR}/${PARTNO}/${REV}/sdriver
	cp -r ../controlr ${RELDIR}/${PARTNO}/${REV}/sdriver
	cp -r ../common   ${RELDIR}/${PARTNO}/${REV}/sdriver
	cp -r ../dacs     ${RELDIR}/${PARTNO}/${REV}/sdriver
	mkdir  ${RELDIR}/${PARTNO}/${REV}/sdriver/build
	cp ../build/loadfcod.fth ${RELDIR}/${PARTNO}/${REV}/sdriver/build
	cp ../build/makefile     ${RELDIR}/${PARTNO}/${REV}/sdriver/build
	cp ../build/load         ${RELDIR}/${PARTNO}/${REV}/sdriver/build
	
