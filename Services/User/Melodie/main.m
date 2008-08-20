#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>

int main(int argc, char **argv)
{
	id pool = [NSAutoreleasePool new];
	NSString *file = [[NSBundle mainBundle] pathForResource:@"Melodie"
	                                                 ofType:@"st"];
	if (nil == file)
	{
		NSLog(@"Unable to find smalltalk file.");
		return 1;
	}
	[SmalltalkCompiler compileString: [NSString stringWithContentsOfFile:file]];
	[pool release];

	return NSApplicationMain(argc, (const char **) argv);
}
