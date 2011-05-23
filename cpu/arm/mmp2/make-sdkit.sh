mkdir -p sdkit-arm
cp ../mmap.fth sdkit-arm
cp twsi.fth gpio.fth mfpr.fth sdkit.fth sdkit-arm
cp ../olpc/1.75/smbus.fth ../olpc/1.75/camera-test.fth  ../olpc/1.75/accelerometer.fth sdkit-arm
cp ../Linux/armforth.static sdkit-arm/forth
cp ../olpc/1.75/build/prefw.dic sdkit-arm/prefw.dic
cp sdkit.sh sdkit-arm
tar cfz sdkit-arm.tgz sdkit-arm
