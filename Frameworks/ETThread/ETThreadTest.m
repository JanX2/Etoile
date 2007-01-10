#import "NSObject+Threaded.h"
#import "ETThreadProxyReturn.h"
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
	NSLog(@"Returning foo in 2 seconds...");
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
	[proxy log:@"Logging in another thread"];
	/*
	 * Try a mthod that returns a value
	 */
	NSString * foo = [proxy getFoo];
	/*
	 * Log something to show that we are continuing and not waiting for
	 * the method to return
	 */
	NSLog(@"[proxy getFoo] called.  Attempting to capitalize the return...");

	/* This line will block until [proxy getFoo] actually returns.
	 * Note that we can interact with wibble as though it were the real
	 * string value.
	 */
	NSLog(@"[proxy getFoo] returned %@", [foo capitalizedString]);

	/*
	 * If we know what we are doing, we can get the real object and get rid of 
	 * the layer of indirection.
	 */
	NSLog(@"%@ = [proxy value]", [(ETThreadProxyReturn*)foo value]);

	/*
	 * Clean up
	 */
	[pool release];
	return 0;
}
