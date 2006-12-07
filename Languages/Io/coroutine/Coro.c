/*
 Credits
 
	Originally based on Edgar Toernig's Minimalistic cooperative multitasking
	http://www.goron.de/~froese/
	reorg by Steve Dekorte and Chis Double
	Symbian and Cygwin support by Chis Double
	Linux/PCC, Linux/Opteron, Irix and FreeBSD/Alpha, ucontext support by Austin Kurahone
	FreeBSD/Intel support by Faried Nawaz
	Mingw support by Pit Capitain
	Visual C support by Daniel Vollmer
	Solaris support by Manpreet Singh
	Fibers support by Jonas Eschenburg
	Ucontext arg support by Olivier Ansaldi  
 
 Notes
 
	This is the system dependent coro code.
	Setup a jmp_buf so when we longjmp, it will invoke 'func' using 'stack'.
	Important: 'func' must not return!
 
	Usually done by setting the program counter and stack pointer of a new, empty stack.
	If you're adding a new platform, look in the setjmp.h for PC and SP members 
	of the stack structure
 
	If you don't see those members, Kentaro suggests writting a simple 
	test app that calls setjmp and dumps out the contents of the jmp_buf.  
	(The PC and SP should be in jmp_buf->__jmpbuf).  
 
	Using something like GDB to be able to peek into register contents right 
	before the setjmp occurs would be helpful also.
 */
 
#include "Base.h" 
#include "Coro.h"
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include "PortableUContext.h"

#ifdef USE_VALGRIND
#include <valgrind/valgrind.h>
#define STACK_REGISTER(coro) \
{ \
	Coro *c = (coro); \
	c->valgrindStackId = VALGRIND_STACK_REGISTER( \
			c->stack, \
			c->stack + c->stackSize); \
}

#define STACK_DEREGISTER(coro) \
	VALGRIND_STACK_DEREGISTER((coro)->valgrindStackId)

#else
#define STACK_REGISTER(coro)
#define STACK_DEREGISTER(coro)
#endif

typedef struct CallbackBlock
{        
	void *context;
	CoroStartCallback *func;
} CallbackBlock;

static CallbackBlock globalCallbackBlock;

Coro *Coro_new(void)
{
	Coro *self = (Coro *)calloc(1, sizeof(Coro));
	self->stackSize = CORO_STACK_SIZE;
	
#ifdef HAS_FIBERS
	self->fiber = NULL;
#else
	self->stack = calloc(1, self->stackSize + 16);
	STACK_REGISTER(self);
#endif
	return self;
}

void Coro_free(Coro *self)
{
#ifdef HAS_FIBERS
	// If this coro has a fiber, delete it.
	// Don't delete the main fiber. We don't want to commit suicide.
	if (self->fiber && !self->isMain) 
	{
		DeleteFiber(self->fiber);
	}
#else
	STACK_DEREGISTER(self);
#endif
	if (self->stack) free(self->stack);
	free(self);
}

// stack

void *Coro_stack(Coro *self)
{
	return self->stack;
}

size_t Coro_stackSize(Coro *self)
{
	return self->stackSize;
}

#if __GNUC__ == 4
uint8_t *Coro_CurrentStackPointer(void) __attribute__ ((noinline));
#endif

uint8_t *Coro_CurrentStackPointer(void)
{ 
	uint8_t a;
	uint8_t *b = &a; // to avoid compiler warning about unused variables
	return b; 
} 

ptrdiff_t Coro_bytesLeftOnStack(Coro *self) 
{
	unsigned char dummy;
	ptrdiff_t p1 = (ptrdiff_t)(&dummy);
	ptrdiff_t p2 = (ptrdiff_t)Coro_CurrentStackPointer();
	int stackMovesUp = p2 > p1;
	ptrdiff_t start = ((ptrdiff_t)self->stack);
	ptrdiff_t end   = start + self->stackSize;
	
	if (stackMovesUp) // like x86
	{
		return end - p1;
	}
	else // like OSX on PPC
	{
		return p1 - start;
	}
}

int Coro_stackSpaceAlmostGone(Coro *self)
{
	return Coro_bytesLeftOnStack(self) < CORO_STACK_SIZE_MIN;
}

void Coro_initializeMainCoro(Coro *self)
{
	self->isMain = 1;
#ifdef HAS_FIBERS	
	// We must convert the current thread into a fiber if it hasn't already been done.
	if ((LPVOID) 0x1e00 == GetCurrentFiber()) // value returned when not a fiber
	{
		// Make this thread a fiber and set its data field to the main coro's address
		ConvertThreadToFiber(self);
	}
	// Make the main coro represent the current fiber
	self->fiber = GetCurrentFiber();
#endif
}

void Coro_startCoro_(Coro *self, Coro *other, void *context, CoroStartCallback *callback)
{	
	globalCallbackBlock.context = context;
	globalCallbackBlock.func    = callback;
	Coro_setup(other, &globalCallbackBlock);
	Coro_switchTo_(self, other);
}

void Coro_StartWithArg(CallbackBlock *block)
{
	(block->func)(block->context);
	printf("Scheduler error: returned from coro start function\n");
	exit(-1);
}

void Coro_Start(void)
{
	CallbackBlock block = globalCallbackBlock;
	Coro_StartWithArg(&block);
}

// --------------------------------------------------------------------

void Coro_UnsupportedPlatformError(void)
{
	printf("Io Scheduler error: no Coro_setupJmpbuf entry for this platform\n.");
	exit(1);
}

void Coro_switchTo_(Coro *self, Coro *next)
{
	#if defined(__SYMBIAN32__)
		ProcessUIEvent();
	#elif defined(HAS_FIBERS)
		SwitchToFiber(next->fiber);
	#elif defined(HAS_UCONTEXT)
		swapcontext(&self->env, &next->env);
	#else
		if (setjmp(self->env) == 0)
		{
			longjmp(next->env, 1);
		}
	#endif
	}

// ---- setup ------------------------------------------

#if defined(HAS_UCONTEXT_ON_PRE_SOLARIS_10)

typedef void (*makecontext_func)(void);

void Coro_setup(Coro *self, void *arg)
{	
	ucontext_t *ucp = (ucontext_t *) &self->env;
	
	getcontext(ucp);
	
	ucp->uc_stack.ss_sp    = Coro_stack(self) + Coro_stackSize(self) - 8;
	ucp->uc_stack.ss_size  = Coro_stackSize(self);
	ucp->uc_stack.ss_flags = 0;
	ucp->uc_link = NULL;
	
	makecontext(ucp, (makecontext_func)Coro_StartWithArg, 1, arg); }


#elif defined(HAS_UCONTEXT)

typedef void (*makecontext_func)(void);

void Coro_setup(Coro *self, void *arg)
{	
	ucontext_t *ucp = (ucontext_t *) &self->env;
	
	getcontext(ucp);
	
	ucp->uc_stack.ss_sp    = Coro_stack(self);
	ucp->uc_stack.ss_size  = Coro_stackSize(self);
#if !defined(__APPLE__)
	ucp->uc_stack.ss_flags = 0;
	ucp->uc_link = NULL;
#endif

	makecontext(ucp, (makecontext_func)Coro_StartWithArg, 1, arg); 
}

#elif defined(HAS_FIBERS)

void Coro_setup(Coro *self, void *arg)
{
	// If this coro was recycled and already has a fiber, delete it.
	// Don't delete the main fiber. We don't want to commit suicide.
	
	if (self->fiber && !self->isMain)
	{
		DeleteFiber(self->fiber);
	}
	
	self->fiber = CreateFiber(Coro_stackSize(self), 
						 (LPFIBER_START_ROUTINE)Coro_StartWithArg, 
						 (LPVOID)arg);
	if (!self->fiber) {
		DWORD err = GetLastError();
		exit(err);
	}
}

#elif defined(__CYGWIN__) 

#define buf (self->env)

void Coro_setup(Coro *self, void *arg)
{
	setjmp(buf);
	buf[7] = (int)(Coro_stack(self) + Coro_stackSize(self) - 16);
	buf[8] = (int)Coro_Start;
}

#elif defined(__SYMBIAN32__)

void Coro_setup(Coro *self, void *arg)
{	
	/* 
	setjmp/longjmp is flakey under Symbian. 
	If the setjmp is done inside the call then a crash occurs. 
	Inlining it here solves the problem 
	*/

	setjmp(self->env);
	self->env[0] = 0;
	self->env[1] = 0;
	self->env[2] = 0;
	self->env[3] = (unsigned int)(Coro_stack(self)) + Coro_stackSize(self) - 64;
	self->env[9] = (int)Coro_Start;
	self->env[8] =  self->env[3] + 32;
}

#elif defined(_BSD_PPC_SETJMP_H_) 

#define buf (self->env)
#define setjmp  _setjmp 
#define longjmp _longjmp

void Coro_setup(Coro *self, void *arg)
{
	size_t *sp = (size_t *)(((intptr_t)Coro_stack(self) + Coro_stackSize(self) - 64 + 15) & ~15);
	
	setjmp(buf);
	
	//printf("self = %p\n", self);
	//printf("sp = %p\n", sp);
	buf[0]  = (int)sp;
	buf[21] = (int)Coro_Start;
	//sp[-4] = (size_t)self; // for G5 10.3
	//sp[-6] = (size_t)self; // for G4 10.4
	
	//printf("self = %p\n", (void *)self);
	//printf("sp = %p\n", sp);
}

#elif defined(__DragonFly__)

#define buf (self->env)

void Coro_setup(Coro *self, void *arg)
{
	void *stack = Coro_stack(self);
	size_t stacksize = Coro_stackSize(self);
	void *func = (void *)Coro_Start;
	
	setjmp(buf);
	
	buf->_jb[2] = (long)(stack + stacksize);
	buf->_jb[0] = (long)func;
	return;
}

#else

#error "Coro.c Error: Coro_setup() function needs to be defined for this platform."

#endif


// old code

/*
 // APPLE coros are handled by PortableUContext now 
#elif defined(_BSD_PPC_SETJMP_H_) 
 
#define buf (self->env)
#define setjmp  _setjmp 
#define longjmp _longjmp
 
 void Coro_setup(Coro *self, void *arg)
 {
	 size_t *sp = (size_t *)(((intptr_t)Coro_stack(self) + Coro_stackSize(self) - 64 + 15) & ~15);
	 
	 setjmp(buf);
	 
	 //printf("self = %p\n", self);
	 //printf("sp = %p\n", sp);
	 buf[0]  = (int)sp;
	 buf[21] = (int)Coro_Start;
	 //sp[-4] = (size_t)self; // for G5 10.3
	 //sp[-6] = (size_t)self; // for G4 10.4
	 
	 //printf("self = %p\n", (void *)self);
	 //printf("sp = %p\n", sp);
 }
 
#elif defined(_BSD_I386_SETJMP_H) 
 
#define buf (self->env)
 
 void Coro_setup(Coro *self, void *arg)
 {
	 size_t *sp = (size_t *)((intptr_t)Coro_stack(self) + Coro_stackSize(self));
	 
	 setjmp(buf);
	 
	 buf[9] = (int)(sp); // esp 
	 buf[12] = (int)Coro_Start; // eip 
						   //buf[8] = 0; // ebp 
 }
 */
 
/* Solaris supports ucontext - so we don't need this stuff anymore

void Coro_setup(Coro *self, void *arg)
{
	// this bit goes before the setjmp call
	// Solaris 9 Sparc with GCC 
	#if defined(__SVR4) && defined (__sun)
		#if defined(_JBLEN) && (_JBLEN == 12) && defined(__sparc)
			#if defined(_LP64) || defined(_I32LPx)
				#define JBTYPE long
				JBTYPE x;
			#else
				#define JBTYPE int
				JBTYPE x;
				asm("ta 3"); // flush register window
			#endif

			#define SUN_STACK_END_INDEX   1
			#define SUN_PROGRAM_COUNTER   2
			#define SUN_STACK_START_INDEX 3 
			
			// Solaris 9 i386 with GCC
			#elif defined(_JBLEN) && (_JBLEN == 10) && defined(__i386)
				#if defined(_LP64) || defined(_I32LPx)
					#define JBTYPE long
					JBTYPE x;
				#else
					#define JBTYPE int
					JBTYPE x;
			#endif
			#define SUN_PROGRAM_COUNTER 5
			#define SUN_STACK_START_INDEX 3 
			#define SUN_STACK_END_INDEX 4
		#endif
	#endif
*/

/* Irix supports ucontext - so we don't need this stuff anymore

#elif defined(sgi) && defined(_IRIX4_SIGJBLEN) // Irix/SGI

void Coro_setup(Coro *self, void *arg)
{
	setjmp(buf);
	buf[JB_SP] = (__uint64_t)((char *)stack + stacksize - 8);
	buf[JB_PC] = (__uint64_t)Coro_Start;
}
*/

/* Linux supports ucontext - so we don't need this stuff anymore

#elif defined(linux)
// Various flavors of Linux.
#if defined(JB_GPR1)
// Linux/PPC
buf->__jmpbuf[JB_GPR1] = ((int) stack + stacksize - 64 + 15) & ~15;
buf->__jmpbuf[JB_LR]   = (int) Coro_Start;
return;

#elif defined(JB_RBX)
// Linux/Opteron
buf->__jmpbuf[JB_RSP] = (long int )stack + stacksize;
buf->__jmpbuf[JB_PC]  = Coro_Start;
return;

#elif defined(JB_SP)

// Linux/x86 with glibc2
buf->__jmpbuf[JB_SP] = (int)stack + stacksize;
buf->__jmpbuf[JB_PC] = (int)Coro_StartWithArg;
// Push the argument on the stack (stack grows downwards)
// note: stack is stacksize + 16 bytes long
((int *)stack)[stacksize/sizeof(int) + 1] = (int)self;
return;

#elif defined(_I386_JMP_BUF_H)
// x86-linux with libc5
buf->__sp = (int)stack + stacksize;
buf->__pc = Coro_Start;
return;

#elif defined(__JMP_BUF_SP)
// arm-linux on the sharp zauras
buf->__jmpbuf[__JMP_BUF_SP]   = (int)stack + stacksize;
buf->__jmpbuf[__JMP_BUF_SP+1] = (int)Coro_Start;
return;

#else

*/


/* Windows supports fibers - so we don't need this stuff anymore

#elif defined(__MINGW32__) 

void Coro_setup(Coro *self, void *arg)
{
	setjmp(buf);
	buf[4] = (int)((unsigned char *)stack + stacksize - 16);   // esp
	buf[5] = (int)Coro_Start; // eip
}

#elif defined(_MSC_VER)

void Coro_setup(Coro *self, void *arg)
{
	setjmp(buf);
	// win32 visual c
	// should this be the same as __MINGW32__?
	buf[4] = (int)((unsigned char *)stack + stacksize - 16);  // esp
	buf[5] = (int)Coro_Start; // eip
}
*/


/* FreeBSD supports ucontext - so we don't need this stuff anymore

#elif defined(__FreeBSD__)
// FreeBSD.
#if defined(_JBLEN) && (_JBLEN == 81)
// FreeBSD/Alpha
buf->_jb[2] = (long)Coro_Start;     // sc_pc
buf->_jb[26+4] = (long)Coro_Start;  // sc_regs[R_RA]
buf->_jb[27+4] = (long)Coro_Start;  // sc_regs[R_T12]
buf->_jb[30+4] = (long)(stack + stacksize); // sc_regs[R_SP]
return;

#elif defined(_JBLEN)
// FreeBSD on IA32
buf->_jb[2] = (long)(stack + stacksize);
buf->_jb[0] = (long)Coro_Start;
return;

#else
Coro_UnsupportedPlatformError();
#endif
*/

/* NetBSD supports ucontext - so we don't need this stuff anymore

#elif defined(__NetBSD__)

void Coro_setup(Coro *self, void *arg)
{
	setjmp(buf);
	#if defined(_JB_ATTRIBUTES)
	// NetBSD i386
	buf[2] = (long)(stack + stacksize);
	buf[0] = (long)Coro_Start;
	#else
	Coro_UnsupportedPlatformError();
	#endif
}
*/

/* Sun supports ucontext - so we don't need this stuff anymore

// Solaris supports ucontext - so we don't need this stuff anymore

void Coro_setup(Coro *self, void *arg)
{
	// this bit goes before the setjmp call
	// Solaris 9 Sparc with GCC 
#if defined(__SVR4) && defined (__sun)
#if defined(_JBLEN) && (_JBLEN == 12) && defined(__sparc)
#if defined(_LP64) || defined(_I32LPx)
#define JBTYPE long
	JBTYPE x;
#else
#define JBTYPE int
	JBTYPE x;
	asm("ta 3"); // flush register window
#endif
	
#define SUN_STACK_END_INDEX   1
#define SUN_PROGRAM_COUNTER   2
#define SUN_STACK_START_INDEX 3 
	
	// Solaris 9 i386 with GCC
#elif defined(_JBLEN) && (_JBLEN == 10) && defined(__i386)
#if defined(_LP64) || defined(_I32LPx)
#define JBTYPE long
					JBTYPE x;
#else
#define JBTYPE int
					JBTYPE x;
#endif
#define SUN_PROGRAM_COUNTER 5
#define SUN_STACK_START_INDEX 3 
#define SUN_STACK_END_INDEX 4
#endif
#endif
					
					
#elif defined(__SVR4) && defined(__sun)
// Solaris
#if defined(SUN_PROGRAM_COUNTER)
// SunOS 9
buf[SUN_PROGRAM_COUNTER] = (JBTYPE)Coro_Start;

x = (JBTYPE)stack;
while ((x % 8) != 0) x --; // align on an even boundary
buf[SUN_STACK_START_INDEX] = (JBTYPE)x;
x = (JBTYPE)((JBTYPE)stack-stacksize / 2 + 15);
while ((x % 8) != 0) x ++; // align on an even boundary
buf[SUN_STACK_END_INDEX] = (JBTYPE)x;

*/

