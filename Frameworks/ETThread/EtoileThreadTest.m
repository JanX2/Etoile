#import "NSObject+Futures.h"
#import "NSObject+Threaded.h"
#import "EtoileThreadProxyReturn.h"
#include <unistd.h>

@interface ThreadTest : NSObject {
}
@end
@implementation ThreadTest 
- (void) log:(NSString*)aString
{
	/* 
	 * Delay to ensure that this logs a while after it is called.
	 * This makes it obvious that it is completing asynchronously.
	 */
	sleep(2);
	NSLog(@"%@", aString);
}
- (id) getFoo
{
	sleep(2);
	return @"foo";
}
@end

int main(void)
{
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	/*
	 * Create an object with its own thread and run loop
	 */
	id proxy = [ThreadTest threadedNew];
	/* 
	 * Test a method that doesn't return a value
	 */
	[proxy log:@"1) Logging in another thread"];
	/*
	 * Try a mthod that returns a value
	 */
	NSString * foo = [proxy getFoo];
	/*
	 * Log something to show that we are continuing and not waiting for
	 * the method to return
	 */
	NSLog(@"2) [proxy getFoo] called.  Attempting to capitalize the return...");

	/* This line will block until [proxy getFoo] actually returns.
	 * Note that we can interact with wibble as though it were the real
	 * string value.
	 */
	NSLog(@"3) [proxy getFoo] is capitalized as %@", [foo capitalizedString]);

	/*
	 * If we know what we are doing, we can get the real object and get rid of 
	 * the layer of indirection.
	 */
	if([foo isFuture])
	{
		NSLog(@"4) Real object returned by future: %@", 
				[(EtoileThreadProxyReturn*)foo value]);
	}
	/*
	 * Clean up
	 */
	[pool release];
	return 0;
}
