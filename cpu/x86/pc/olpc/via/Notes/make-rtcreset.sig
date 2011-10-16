Added an "a2" tag with a test key for which I have the corresponding private key:

$ cp testkeys/lease.public /e/lease.pub
ok load u:\lease.pub
ok loaded " a2" $add-tag

Rolled back the clock by one day and verified that it was detected:

ok now today swap 1- swap  clock-node @ iselect set-time iunselect
ok rtc-rollback? .
ffffffff
ok dev /chosen .properties dend

Got CURRENTRTC value from rtc-timestamp and NONCE value from rtc-count

$ CURRENTRTC=20110510T200549Z
$ NONCE=0000000132

ok .mfg-data

Got SERIAL-NUMBER from SN
Got UUID from U#

$ SN=SHC005007B7
$ UUID=1273E0EC-AEF1-9FF6-45B2-FB706DC24B8D

Made a newrtc value by decrementing the month

$ NEWRTC=20110410T200549Z

$ echo -n ${SN}:${UUID}:${CURRENTRTC}:${NONCE}:${NEWRTC} >signed-data
$ cat signed-data
SHC005007B7:1273E0EC-AEF1-9FF6-45B2-FB706DC24B8D:20110512T003512Z:0000000135:20110412T003512Z
$ cd /space/bios-crypto/build
$ ./sig01 sha256 testkeys/lease signed-data >sig
$ cat sig
sig01: sha256 e842349e413bfd424426bdacd1cb46fd8e6c5e516ed80a8a849f410203010001 7e65d0d158cbe8b891a099900ab0f8a46618a8208203283b13158103e98ff6deebec8bd0f77534c1a30be0484f49f3b31f78eaaa374329240e7735a68e5c55527c927b7e47d97c9b2d6a145f00e7b1fdbe1e1b8a6d6863079f620a3b8f74c166cdec2a68dcc36a0218e0525b1dcbf95d803f81ef60460ba3fadc468c108f1ded5a941b60fd6896fe694d2abf41945242d4cd36ad42979baf911d70b4f73a76d5afe19a9909870ff244833a80b9d470416a37b03fcf85d79feca21dd4ea3b29741a9801ef567769f945badf625068979bc5635a85a012a381bb1344e7645345ed8df5ca4dccda6b0c5050126716e9d9a8dfdb572f0aa286cb1e71e758e58f5b92
$ echo -n rtc01: ${SN} ${CURRENTRTC} ${NONCE} ${NEWRTC} "" | cat - sig >rtcreset.sig
$ cat rtcreset.sig
rtc01: SHC005007B7 20110512T003512Z 0000000135 20110412T003512Z sig01: sha256 e842349e413bfd424426bdacd1cb46fd8e6c5e516ed80a8a849f410203010001 7e65d0d158cbe8b891a099900ab0f8a46618a8208203283b13158103e98ff6deebec8bd0f77534c1a30be0484f49f3b31f78eaaa374329240e7735a68e5c55527c927b7e47d97c9b2d6a145f00e7b1fdbe1e1b8a6d6863079f620a3b8f74c166cdec2a68dcc36a0218e0525b1dcbf95d803f81ef60460ba3fadc468c108f1ded5a941b60fd6896fe694d2abf41945242d4cd36ad42979baf911d70b4f73a76d5afe19a9909870ff244833a80b9d470416a37b03fcf85d79feca21dd4ea3b29741a9801ef567769f945badf625068979bc5635a85a012a381bb1344e7645345ed8df5ca4dccda6b0c5050126716e9d9a8dfdb572f0aa286cb1e71e758e58f5b92
$ mount /e; mkdir -p /e/security; cp rtcreset.sig /e/security; umount /e

ok get-my-sn . date-bad? . load-crypto .
0 0 0
ok " u:" dn-buf place  filesystem-present? .
ffffffff
ok 
