#import "UIServer.h"

UIServer *_sharedServer;

@implementation UIServer

+ (id) server
{
	if (nil == _sharedServer)
	{
		_sharedServer = [[UIServer alloc] init];
	}
	return _sharedServer;
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	_shelf = [[ETOverlayShelf alloc] init];
	_shelfConnection = [[NSConnection alloc] initWithReceivePort: [NSPort port]
	                                               sendPort: [NSPort port]];
	[_shelfConnection setRootObject: _shelf];
	if ([_shelfConnection registerName:@"Etoile/SystemPickboard"] == NO)
	{
		[NSException raise:@"DOException"
		            format:@"Can't register SystemPickboard with DO server"];
	}	
	
	_sidebar = [[SidebarController alloc] init];
	[_sidebar show];
}

- (id) init
{
	SUPERINIT;
	ETUIItemFactory *factory = [ETUIItemFactory factory];
	_rootGroup = [[factory itemGroup] retain];

	_connection = [[NSConnection alloc] initWithReceivePort: [NSPort port]
	                                               sendPort: [NSPort port]];
	[_connection setRootObject: _rootGroup];
	if ([_connection registerName:@"Etoile/RootGroup"] == NO)
	{
		[NSException raise:@"DOException"
		            format:@"Can't register RootGroup with DO server"];
	}
	

	return self;
}
- (void) dealloc
{
	NSLog(@"UIServer dealocated");
	[_connection release];
	[_rootGroup release];
	[_shelf release];
	[_shelfConnection release];
	[super dealloc];
}
- (id) rootGroup
{
	return _rootGroup;
}
@end
