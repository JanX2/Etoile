#import "CLCompositor.h"

@implementation CLCompositor

- (id) init {
	self = [super init];
	images = [NSMutableDictionary new];
	cache = [CLCache cache];
	return self;
}

- (void) dealloc {
	[super dealloc];
	[images release];
}

- (void) addImage: (NSImage*) image named: (NSString*) name {
	[images setObject: image forKey: name];
}

- (void) error: (NSString*) msg {
	NSLog (@"=== Camaelon Error ===");
}

- (void) setName: (NSString*) n { ASSIGN (name, n); }

- (void) drawOn: (NSView*) view {

	NSRect rect = [view bounds];

	NSImage* image = [cache imageNamed: name withSize: rect.size];
	
	if (image == nil)
	{
		// We need to cache the drawing..

		image = [[NSImage alloc] initWithSize: rect.size];
		[image lockFocus];
		[self drawInRect: NSMakeRect (0,0,rect.size.width,rect.size.height)];
		[image unlockFocus];

		[cache setImage: image named: name];
		[image autorelease]; // as we use it just after..
	}

	if ([view isFlipped]) {
		[image compositeToPoint: NSMakePoint (rect.origin.x, rect.origin.y + rect.size.height)
			operation: NSCompositeSourceOver];	
	}
	else {
		[image compositeToPoint: NSMakePoint (rect.origin.x, rect.origin.y)
			operation: NSCompositeSourceOver];	
	}
}

@end
