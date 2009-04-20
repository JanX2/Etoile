#import "XCBConnection.h"
#import "PMConnectionDelegate.h"

int main(void)
{
	[NSAutoreleasePool new];
	[PMConnectionDelegate new];

	[[NSRunLoop currentRunLoop] run];
}
