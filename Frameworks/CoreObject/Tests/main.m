#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <UnitKit/UKRunner.h>
#import <UnitKit/UKTestHandler.h>
#import "TestCommon.h"

int main (int argc, const char *argv[])
{
    @autoreleasepool {
		UKRunner *runner = [UKRunner new];

		[[UKTestHandler handler] setQuiet: YES];

		[runner runTestsInBundle: [NSBundle mainBundle] principalClass: [EditingContextTestCase class]];
		[runner reportTestResults];
		
    }
    return 0;
}
