#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/resource.h>

#define BOOSTED_PRIORITY 5

static int oldpid = -1;
static int oldPriority;

//Drop the priority of the last process back to what it was before we boosted it
int drop_priority()
{
	if(oldpid > 0)
	{
		//Reset the priority of the last process
		if(setpriority(PRIO_PROCESS, oldpid, oldPriority))
		{
			perror("Error while dropping priority for last process");
		}
	}
}

void term(int sig)
{
	drop_priority();
	printf("Signal %d caught.  Exiting.", sig);
	exit(1);
}

//Signals which can kill the process

int main(void)
{
	int pid;
	//Make sure we de-prioritise the boosted process and exit if we catch any
	//signal.
	for(int sig = 1 ; sig < 32 ; sig++)
	{
		signal(sig, term);
	}	
	//Read a stream of pids from stdin
	while(fread(&pid, sizeof(int), 1, stdin) > 0)
	{
		drop_priority();
		oldpid = pid;
		oldPriority = getpriority(PRIO_PROCESS, pid);
		//If we successfully for the old priority
		if(oldPriority < 0)
		{
			oldpid = -1;
			perror("Error while retrieving priority of process");
		}
		else
		{
			//Boost the foreground process
			setpriority(PRIO_PROCESS, pid, BOOSTED_PRIORITY);
		}
	}
	drop_priority();
	return 0;
}
