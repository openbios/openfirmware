#!/bin/sh
dd if=/dev/zero of=filesystem.img bs=512 seek=20K count=1
/sbin/mke2fs -F filesystem.img
dd if=filesystem.img of=fs.img bs=512 seek=1
rm filesystem.img
/sbin/sfdisk -L -uS -C 5 -H 128 -S 32 fs.img <<EOF
,,L,*
;
;
;
EOF
sudo mount -o loop,offset=512 fs.img mnt
