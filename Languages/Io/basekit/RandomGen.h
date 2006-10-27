

#ifndef RANDOMGEN_DEFINED
#define RANDOMGEN_DEFINED 1

#ifdef __cplusplus
extern "C" {
#endif

#define RANDOMGEN_N 624

typedef struct
{
	unsigned long mt[RANDOMGEN_N]; // the array for the state vector
	int mti; // mti==N+1 means mt[N] is not initialized 
} RandomGen;

RandomGen *RandomGen_new(void);
void RandomGen_free(RandomGen *self);

void RandomGen_setSeed(RandomGen *self, unsigned long seed);
void RandomGen_chooseRandomSeed(RandomGen *self);

// generates a random number on between 0.0 and 1.0 
double RandomGen_randomDouble(RandomGen *self);

int RandomGen_randomInt(RandomGen *self);

#ifdef __cplusplus
}
#endif
#endif
