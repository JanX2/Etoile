#include <stdio.h>
#import <Foundation/Foundation.h>
#import "Microblogger.h"

int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	if(argc != 3)
	{
		fprintf(stderr, "Usage: %s {username} {password}", argv[0]);
	}
	NSString * username = [NSString stringWithCString:argv[1]];
	NSString * password = [NSString stringWithCString:argv[2]];
	[[[Microblogger alloc] init] runWithUsername:username password:password];
	return 0;
}
