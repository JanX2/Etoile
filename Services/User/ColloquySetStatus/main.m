#import <Cocoa/Cocoa.h>
#import "ColloquySetStatus.h"

int main(int argc, char *argv[])
{
	[[NSAutoreleasePool alloc] init];
	[[[ColloquySetStatus alloc] init] run];
	return 0;
}
