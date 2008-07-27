#import <Corner.h>
#import <SmalltalkKit/SmalltalkKit.h>


/**
 * Basic implementation of the corner delegate which does nothing.
 *
 * Smalltalk scripts can implement categories on this which actually do
 * something useful.
 */
@interface CornerDelegate : NSObject {
	id state;
}
- (void) enterTopLeft;
- (void) exitTopLeftAfter:(int)seconds;
- (void) enterTopRight;
- (void) exitTopRightAfter:(int)seconds;
- (void) enterBottomLeft;
- (void) exitBottomLeftAfter:(int)seconds;
- (void) enterBottomRight;
- (void) exitBottomRightAfter:(int)seconds;
@end
@implementation CornerDelegate
- (void) enterTopLeft
{
	NSLog(@"Entered top left corner");
}
- (void) exitTopLeftAfter:(int)seconds
{
	NSLog(@"Exited corner after %d seconds", seconds);
}
- (void) enterTopRight;
{
	NSLog(@"Entered top right corner");
}
- (void) exitTopRightAfter:(int)seconds;
{
	NSLog(@"Exited corner after %d seconds", seconds);
}
- (void) enterBottomLeft;
{
	NSLog(@"Entered bottom left corner");
}
- (void) exitBottomLeftAfter:(int)seconds;
{
	NSLog(@"Exited corner after %d seconds", seconds);
}
- (void) enterBottomRight;
{
	NSLog(@"Entered bottom right corner");
}
- (void) exitBottomRightAfter:(int)seconds;
{
	NSLog(@"Exited corner after %d seconds", seconds);
}
@end

@implementation Corner
/**
 * Load the scripts from defaults, setting some defaults if 
 * there are none.  The default scripts need making more sensible.
 * The current ones just unhide the application, which is only 
 * useful for testing.
 */
- (void) loadScripts:(id)ignore
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSString *scripts = [[defaults stringForKey:@"CornerScript"] retain];
	if (scripts && ![scripts isEqualToString:@""])
	{
		[[[[Parser alloc] init] 
			parseString:scripts] compileWith:defaultCodeGenerator()];
	}
}
/** 
 * Initialise the scripting engine and set up a timer to periodically
 * poll the mouse position.
 */
- (id) init
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	delegate = [CornerDelegate new];
	/* Set up the scripts */
	[self loadScripts:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadScripts:)
												 name:NSUserDefaultsDidChangeNotification
	                                           object:nil];
	[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.2
	                                 target:self
								   selector:@selector(periodic:)
								   userInfo:nil
								    repeats:YES];

	/* Get the X11 Window we use with our query */
	display = XOpenDisplay(NULL);
	w = DefaultRootWindow(display);
	[[NSRunLoop currentRunLoop] run];
	/* Should not be reached */
	return self;
}
/**
 * Returns an NSRect containing the mouse position (x,y) and
 * the size of the root window currently below the mouse 
 * (width, height).  This should be moved to a framework.
 */
- (NSRect) globalMousePosition
{
	Window root, child;
	int x,y,x1,y1;
	unsigned int mask, other;
	XQueryPointer(display, w, &root, &child, &x, &y, &x1, &y1, &mask);
	/* If the cursor has moved to a different screen
	 * Get the dimensions of it */
	if(root != lastRoot)
	{
		XGetGeometry(display, root, &child, &x1,&y1,&rootWidth,&rootHeight,&mask, &other);
	}
	return NSMakeRect((float)x, (float)y,(float)rootWidth,(float)rootHeight);
}
/**
 * Returns an NSPoint representing the position of the mouse
 * scaled to between 0 and 1, indicating the position on the
 * screen.
 */
- (NSPoint) globalRelativeMousePosition
{
	NSRect mouse = [self globalMousePosition];
	NSPoint relative = {
		mouse.origin.x/mouse.size.width,
		mouse.origin.y/mouse.size.height
	};
	return relative;
}
- (void) outCorner
{
	// If we are exiting a corner...
	if(lastCorner != 0)
	{
		int seconds = time(NULL) - inCornerTime;
		switch(lastCorner)
		{
			case 1:
				[delegate exitTopLeftAfter:seconds];
				break;
			case 2:
				[delegate exitTopRightAfter:seconds];
				break;
			case 3:
				[delegate exitBottomRightAfter:seconds];
				break;
			case 4:
				[delegate exitBottomLeftAfter:seconds];
				break;
		}
		lastCorner = 0;
	}
}
- (void) inCorner:(int)corner
{
	// If we have jumped from one corner to another
	if (corner != lastCorner)
	{
		[self outCorner];
		lastCorner = corner;
		inCornerTime = time(NULL);
		switch(corner)
		{
			case 1:
				[delegate enterTopLeft];
				break;
			case 2:
				[delegate enterTopRight];
				break;
			case 3:
				[delegate enterBottomRight];
				break;
			case 4:
				[delegate enterBottomLeft];
				break;
		}
	}
}
/**
 * Periodically poll the mouse and check if it is in a corner.
 */
- (void) periodic:(id)sender
{
	const int cornerSize = 2;
	NSRect mouse = [self globalMousePosition];
	if(mouse.origin.x < cornerSize && mouse.origin.y < cornerSize)
	{
		[self inCorner:1];
	}
	else if(mouse.origin.x < cornerSize && mouse.origin.y > mouse.size.height - cornerSize)
	{
		[self inCorner:4];
	}
	else if(mouse.origin.x > mouse.size.width - cornerSize && mouse.origin.y < cornerSize)
	{
		[self inCorner:2];
	}
	else if(mouse.origin.x > mouse.size.width -cornerSize && mouse.origin.y > mouse.size.height - cornerSize)
	{
		[self inCorner:3];
	}
	else
	{
		[self outCorner];
	}
}
@end
