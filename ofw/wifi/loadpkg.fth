purpose: Load file for supplicant support package

\ Encryption/decryption
[ifdef] 386-assembler
fload ${BP}/ofw/wifi/sha1.fth
[then]
fload ${BP}/ofw/wifi/hmacsha1.fth
fload ${BP}/ofw/wifi/aes.fth
fload ${BP}/ofw/wifi/md5.fth
fload ${BP}/ofw/wifi/rc4.fth

fload ${BP}/ofw/wifi/data.fth		\ Data structures
fload ${BP}/ofw/wifi/eapol.fth		\ EAPOL-key processing

\ Usage:
\
\ In devices.fth or some such:
\ support-package: supplicant
\ fload ${BP}/ofw/wifi/loadpkg.fth
\ end-support-package
\

