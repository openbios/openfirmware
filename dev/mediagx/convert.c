void
convert_frequency (sample, phase, fin, fout, inbuf, num_in, outbuf, getsample)
    long *sample;
    long *phase;
    int fin;
    int fout;
    void *inbuf;
    int num_in;
    short *outbuf;
    long (*getsample)();
{
    register long s, s1;	/* current and next sample values */
    register int next_input;	/* counts to next input sample */
    register long delta;	/* diff. between successive output samples */
    void **inp;			/* input pointer */

    inp = inbuf;		
    next_input = *phase;
    s = *sample;		

    while (1) { /* Loop over output samples */
	 if ((next_input -= fin) <= 0) {
	     /* It`s time to get a new input sample ... */

	     if (--num_in < 0) {	      /* No more input samples? */
		  *phase = next_input + fin;  /* Return sample phase */
		  *sample = s;                /* Return last sample */
		  return;
	     }
	     next_input += fout;     /* Update counts to next input sample */
	     s1 = getsample(&inp);   /* Get new input sample */
    
	     /*
	      * Compute the delta between successive output samples; its the
	      * difference between old and new input samples, scaled by the
	      * ratio output-frequency/input-frequency
	      */

	     /*
	      * On x86 systems, it is worthwhile to hand-optimize the
	      * code generated for this calculation.  The x86 IMUL
	      * instruction generates a 64-bit result, and the IDIV
	      * instruction takes a 64-bit divident.  By using that pair
	      * of instructions one after the other (IMUL then IDIV),
	      * the fin/fout scaling can be done without loss of precision
	      */
	     delta = ((s1-s)/fout)*fin;	/* scaled delta */
    
	     /*
	      * delta is the new "delta" value, with the implied binary
	      * point in the middle of the word, i.e. between bits 15 and 16
	      */
	 }

	 s += delta;			/* Update sample value */

	 *outbuf = (short)(s >> 16);	/* Store 16 MSB of sample */

	 outbuf += 2;		/* Skip to next sample - both channels */
				/* outbuf is a (short) pointer, so =+ 2 */
				/* skips 2 shortwords */
    }
}

short inbuf[] = { 0000, 0000, 0xffc0, 0xffb0, 0x0154, 0x00a4 };
short outbuf[300];

long
gs(p)
     short **p;
{
     long l;
     l = **p;
     ++(*p);
     return(l<<16);
}

main()
{
   int i;
   int sample = 0, phase = 0;

   convert_frequency (&sample, &phase, 8, 48, inbuf, 6, outbuf, gs);
   for(i=0; i < 72; i++)
     printf("%04x ", outbuf[i] & 0xffff);
   printf("\n");
   printf("sample %x phase %x\n", sample, phase);
}
