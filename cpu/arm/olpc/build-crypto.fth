purpose: Common code for fetching and building the crypto support code

\ The macro CRYPTO_VERSION must be defined externally

\needs to-file       fload ${BP}/forth/lib/tofile.fth
\needs $md5sum-file  fload ${BP}/forth/lib/md5file.fth

" wget -q http://dev.laptop.org/pub/firmware/crypto/${KEYS}/os.public        -O os.public"        expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/${KEYS}/fw.public        -O fw.public"        expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/${KEYS}/fs.public        -O fs.public"        expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/${KEYS}/lease.public     -O lease.public"     expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/${KEYS}/developer.public -O developer.public" expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/bios_verify-${CRYPTO_VERSION}.img" expand$ $sh
" wget -q http://dev.laptop.org/pub/firmware/crypto/bios_verify-${CRYPTO_VERSION}.img.md5" expand$ $sh

to-file md5string  " *"  " bios_verify-${CRYPTO_VERSION}.img" expand$ $md5sum-file
" cmp md5string bios_verify-${CRYPTO_VERSION}.img.md5" expand$ $sh

" cp bios_verify-${CRYPTO_VERSION}.img verify.img" expand$ $sh
" rm bios_verify-${CRYPTO_VERSION}.img.md5 md5string" expand$ $sh

\ This forces the creation of an verify.log file, so we don't re-fetch
writing verify.version
" ${CRYPTO_VERSION}"n" expand$  ofd @ fputs
ofd @ fclose
