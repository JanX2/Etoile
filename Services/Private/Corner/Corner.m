#import <Corner.h>
#import <SmalltalkKit/SmalltalkKit.h>
#include <math.h>


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
	[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.1
	                                 target:self
								   selector:@selector(periodic:)
								   userInfo:nil
								    repeats:YES];

	/* Get the X11 Window we use with our query */
	display = XOpenDisplay(NULL);
	w = DefaultRootWindow(display);
	gesture = [NSMutableString new];
	[[NSRunLoop currentRunLoop] run];
	/* Should not be reached */
	return self;
}
/**
 * Returns an NSRect containing the mouse position (x,y) and
 * the size of the root window currently below the mouse 
 * (width, height).  This should be moved to a framework.
 */
- (NSRect) globalMousePositionWithModifiers:(BOOL*)isModified
{
	Window root, child;
	int x,y,x1,y1;
	unsigned int mask, other;
	const int modifiers = ShiftMask | ControlMask;
	XQueryPointer(display, w, &root, &child, &x, &y, &x1, &y1, &mask);
	*isModified = ((mask & modifiers) == modifiers);
	/* If the cursor has moved to a different screen
	 * Get the dimensions of it */
	if(root != lastRoot)
	{
		XGetGeometry(display, root, &child, &x1,&y1,&rootWidth,&rootHeight,&mask, &other);
	}
	return NSMakeRect((float)x, (float)y,(float)rootWidth,(float)rootHeight);
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
- (char) trackGesture:(NSRect) mouse
{
	int dx = lastPosition.origin.x - mouse.origin.x;
	int dy = lastPosition.origin.y - mouse.origin.y;
	lastPosition = mouse;
	int adx = abs(dx);
	int ady = abs(dy);
	// Ignore small movements
	if (adx + ady > 20)
	{
		// Ignore small relative displacements in one dimension
		if ((adx < ady) && ((adx == 0) || (ady / adx > 2)))
		{
			if (dx > 0)
			{
				return '1';
			}
			else
			{
				return '5';
			}
		}
		else if ((ady < adx) && ((ady == 0) || (adx / ady > 2)))
		{
			if (dy > 0)
			{
				return '7';
			}
			else
			{
				return '3';
			}
		}
		else if (dx >= 0)
		{
			if (dy >= 0)
			{
				return '8';
			}
			else
			{
				return '6';
			}
		}
		else
		{
			if (dy >= 0)
			{
				return '2';
			}
			else
			{
				return '4';
			}
		}
	}
	return '0';
}
/**
 * Periodically poll the mouse and check if it is in a corner.
 */
- (void) periodic:(id)sender
{
	const int cornerSize = 2;
	BOOL modifiers;
	NSRect mouse = [self globalMousePositionWithModifiers:&modifiers];
	if (modifiers && !inGesture)
	{
		NSLog(@"Starting gesture");
		lastPosition = mouse;
		lastDirection = '\0';
	}
	else if (inGesture && !modifiers)
	{
		NSLog(@"Ending Gesture %@", gesture);
		[gesture setString:@""];
	}
	else if(inGesture)
	{
		char direction = [self trackGesture:mouse];
		if (direction != lastDirection && direction != '0')
		{
			[gesture appendFormat:@"%c", direction];
			lastDirection = direction;
		}
	}
	inGesture = modifiers;
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
