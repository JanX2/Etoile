#import "TextController.h"
#import <CoreObject/CoreObject.h>

@implementation TextController

- (id)initWithDocument: (id)document isSharing: (BOOL)sharing;
{
	self = [super initWithWindowNibName: @"TextDocument"];
	
	if (!self) { [self release]; return nil; }
	
	doc = document; // weak ref
	isSharing = sharing;
	
	return self;
}

- (id)initWithDocument: (id)document
{
	return [self initWithDocument:document isSharing: NO];
}

- (Document*)projectDocument
{
	return doc;
}

- (void)windowDidLoad
{
	[textView setDelegate: self];
	
	NSString *label = [[doc rootDocObject] label];
	[[textView textStorage] setAttributedString: [[[NSAttributedString alloc] initWithString: label] autorelease]];	
}

- (void)textDidChange:(NSNotification*)notif
{
	[[doc rootDocObject] setLabel: [[textView textStorage] string]];
    
    // FIXME: Use Metadata
//	[[doc objectContext] commitWithType:kCOTypeMinorEdit
//					   shortDescription:@"Edit Text"
//						longDescription:@"Edit Text"];
    
    [[[doc objectGraphContext] editingContext] commit];
}

@end
