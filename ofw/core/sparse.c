// Create a sparse disk image file that can be accessed from OFW
// running under Linux using /sparseosfile, after loading sparseosfile.fth
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

#define BLKLEN 4096
char buf[BLKLEN];
int blen = BLKLEN;

int allzero(char *buf, size_t len)
{
    long *p = (long *)buf;
    len /= sizeof(long);
    while (len--)
        if(*p++)
            return 0;
    return 1;
}

int blockmap[10000];

main(int argc, char **argv)
{
    int abs_blockno = 0;
    int rel_blockno = 0;
    int outfile;

    outfile = creat("outfile", 0666);
    if (outfile < 0) {
        perror("sparse");
        (void)exit(1);
    }

    while(read(0, buf, BLKLEN) == BLKLEN) {
        if (!allzero(buf, BLKLEN)) {
            write(outfile, buf, BLKLEN);
            blockmap[rel_blockno++] = abs_blockno;
        }
        abs_blockno++;
    }
    write(outfile, blockmap, rel_blockno*sizeof(int));
    write(outfile, &rel_blockno, sizeof(int));
    write(outfile, &abs_blockno, sizeof(int));
    write(outfile, &blen, sizeof(int));
    close(outfile);
}
