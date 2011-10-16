FTHFILES= \
  ../accelerometer.fth \
  ../../../mmp2/gpio.fth \
  ../../../mmp2/mfpr.fth \
  ../../../mmap.fth \
  ../smbus.fth \
  ../../../mmp2/twsi.fth \
  ./sdkit.fth

SHFILES= ./sdkit.sh

DICFILES= ../build/prefw.dic 

WRAPPER=../../../Linux/armforth.static

D=sdkit-xo175

sdkit-xo175.tgz: FORCE
	mkdir -p $D
	cp $(WRAPPER) $D/forth
	cp $(FTHFILES) $D
	cp $(DICFILES) $D
	cp $(SHFILES) $D
	tar cfz $@ $D/forth $D/*.fth $D/*.sh $D/*.dic
	rm -rf $D

FORCE:
