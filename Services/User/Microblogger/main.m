#import <Foundation/Foundation.h>
#import "Microblogger.h"

int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	NSString * username = [[NSString stringWithCString:argv[1]] retain];
	NSString * password = [[NSString stringWithCString:argv[2]] retain];
	[[[Microblogger alloc] init] runWithUsername:username password:password];
	return 0;
}
