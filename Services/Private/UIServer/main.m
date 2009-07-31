#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import "UIServer.h"

int main(int argc, char **argv)
{
	[[NSAutoreleasePool alloc] init];

	UIServer *server = [UIServer server];
	NSApplication *app = [ETApplication sharedApplication];
	[app setDelegate: server];
	[app run];
	return 0;
}

