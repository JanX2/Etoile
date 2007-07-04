#import <Corner.h>

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
	[scripts release];
	scripts = [[defaults arrayForKey:@"CornerScripts"] retain];
	if(scripts == nil)
	{
		/* Scripts in clockwise order from the
		 * top left corner */
		//TODO: Put these in a plist
		scripts = [[NSArray arrayWithObjects:
						/* No actions for top corners yet */
						@"Transcript showLine:'Top Left!'.",
						@"Transcript showLine:'Top Right!'.",
						/* Activate Screensaver (xscreensaver) */
					    @"args := #('-activate').\
						task := NSTask launchedTaskWithLaunchPath:'xscreensaver-command' arguments:args.\
						task waitUntilExit.",
						/* Show / hide desktop */
						@"Environment includeFramework:'XWindowServerKit'.\
						screen := NSScreen mainScreen.\
						isShown := screen isShowingDesktop.\
						screen setShowingDesktop:(isShown not).",
						nil] retain];
		[defaults setObject:scripts forKey:@"CornerScripts"];
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
	/* Set up scripting */
	scriptingEnvironment = [[STEnvironment sharedEnvironment] retain];
	smalltalkEngine = [[STEngine engineForLanguage:@"Smalltalk"] retain];
	[scriptingEnvironment setObject:[[NSProcessInfo processInfo] arguments] 
	                        forName:@"ARGS"];
	[scriptingEnvironment loadModule:@"SimpleTranscript"];
/*	[scriptingEnvironment setObject:NSApp
	                        forName:@"Application"];*/
	[scriptingEnvironment setObject:scriptingEnvironment
	                        forName:@"Environment"];
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
	w = DefaultRootWindow(XOpenDisplay(NULL));
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
	Display * display = (Display*) XOpenDisplay(NULL);
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
/**
 * Runs the script associated with a given corner of the screen.
 * Corners are numbered from 1 to 4, clockwise, starting at the
 * top left.
 */
- (void) invokeActionForCorner:(int)aCorner
{
	NS_DURING
		NSLog(@"In corner %d", aCorner);
		NSString * script = [scripts objectAtIndex:aCorner-1];
		if(script != nil && ![script isEqualToString:@""])
		{
			[smalltalkEngine interpretScript:[scripts objectAtIndex:aCorner-1]
			                       inContext:scriptingEnvironment];
		}
	NS_HANDLER
		/* Log script exceptions */
		NSLog(@"%@",localException);
	NS_ENDHANDLER
}

/**
 * Macro to test whether the mouse has entered a give corner
 * and fire off the correct action if it has.
 */
#define IF_IN_CORNER_FOR_TIME(corner, time) \
	if(lastCorner != (corner))\
	{\
		inCorner = NO;\
		cornerWaitCount = 0;\
	}\
	else\
	{\
		cornerWaitCount++;\
	}\
	lastCorner = corner;\
	if(!inCorner && cornerWaitCount >= time)\
	{\
		inCorner = YES;\
		[self invokeActionForCorner:corner];\
	}
/**
 * The number of polls that the mouse should need to stay
 * in the corner for before the action is invoked.
 *
 * This should probably move into a default at some point
 * so users can configure it.
 */
#define delay 2
/**
 * Periodically poll the mouse and check if it is in a corner.
 */
- (void) periodic:(id)sender
{
	const int cornerSize = 2;
	NSRect mouse = [self globalMousePosition];
	if(mouse.origin.x < cornerSize && mouse.origin.y < cornerSize)
	{
		IF_IN_CORNER_FOR_TIME(1,delay);
	}
	else if(mouse.origin.x < cornerSize && mouse.origin.y > mouse.size.height - cornerSize)
	{
		IF_IN_CORNER_FOR_TIME(4,delay);
	}
	else if(mouse.origin.x > mouse.size.width - cornerSize && mouse.origin.y < cornerSize)
	{
		IF_IN_CORNER_FOR_TIME(2,delay);
	}
	else if(mouse.origin.x > mouse.size.width -cornerSize && mouse.origin.y > mouse.size.height - cornerSize)
	{
		IF_IN_CORNER_FOR_TIME(3,delay);
	}
	else
	{
		lastCorner = 0;
		inCorner = NO;
	}
}
@end
