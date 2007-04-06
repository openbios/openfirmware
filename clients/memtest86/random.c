/* concatenation of following two 16-bit multiply with carry generators */
/* x(n)=a*x(n-1)+carry mod 2^16 and y(n)=b*y(n-1)+carry mod 2^16, */
/* number and carry packed within the same 32 bit integer.        */
/******************************************************************/

unsigned int rand( void );           /* returns a random 32-bit integer */
void  rand_seed( unsigned int, unsigned int );      /* seed the generator */

/* return a random float >= 0 and < 1 */
#define rand_float          ((double)rand() / 4294967296.0)

static unsigned int SEED_X = 521288629;
static unsigned int SEED_Y = 362436069;


unsigned int rand ()
   {
   static unsigned int a = 18000, b = 30903;

   SEED_X = a*(SEED_X&65535) + (SEED_X>>16);
   SEED_Y = b*(SEED_Y&65535) + (SEED_Y>>16);

   return ((SEED_X<<16) + (SEED_Y&65535));
   }


void rand_seed( unsigned int seed1, unsigned int seed2 )
   {
   if (seed1) SEED_X = seed1;   /* use default seeds if parameter is 0 */
   if (seed2) SEED_Y = seed2;
   }
