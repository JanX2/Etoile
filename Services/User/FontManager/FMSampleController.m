#import "Compat.h"
#import "FMSampleController.h"

@implementation FMSampleController

- (id) init
{
	[super init];
	
	sizes = [NSArray arrayWithObjects: [NSNumber numberWithInt:9],
		[NSNumber numberWithInt:10], [NSNumber numberWithInt:11],
		[NSNumber numberWithInt:12], [NSNumber numberWithInt:13],
		[NSNumber numberWithInt:14], [NSNumber numberWithInt:18],
		[NSNumber numberWithInt:24], [NSNumber numberWithInt:36],
		[NSNumber numberWithInt:48], [NSNumber numberWithInt:64],
		[NSNumber numberWithInt:72], [NSNumber numberWithInt:96],
		[NSNumber numberWithInt:144], [NSNumber numberWithInt:288], nil];
	RETAIN(sizes);
	
	[[NSNotificationCenter defaultCenter] addObserver: self
    selector: @selector(controlTextDidEndEditing:)
    name: NSControlTextDidEndEditingNotification object: sizeField];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

- (void) setFonts: (NSArray *)newFonts
{
	ASSIGN(fonts, newFonts);
	[self update];
}

- (NSArray *) fonts
{
	return fonts;
}

- (void) setForegroundColor: (NSColor *)newColor
{
	ASSIGN(foregroundColor, newColor);
	[self update];
}

- (NSColor *) foregroundColor
{
	return foregroundColor;
}

- (void) setBackgroundColor: (NSColor *)newColor
{
	ASSIGN(backgroundColor, newColor);
	[self update];
}

- (NSColor *) backgroundColor
{
	return backgroundColor;
}

- (void) setSampleText: (NSString *)newText
{
	ASSIGN(sampleText, newText);
	[self update];
}

- (NSString *) sampleText
{
	return sampleText;
}

- (void) update
{

	/* Update size controls */

	[sizeField setObjectValue:fontSize];
	[sizeSlider setObjectValue:fontSize];


	NSEnumerator *fontEnumerator = [[self fonts] objectEnumerator];
	NSFont *currentFont;
	
	NSTextStorage *fontSample = [sampleView textStorage];

	// "The quick brown fox jumps over a lazy dog."
	//initWithString:attributes:
	//addAttribute:value:range:
	//NSMakeRange(0, )
	while (currentFont = [fontEnumerator nextObject])
	{
    NSAttributedString *fontName =
			[[NSAttributedString alloc] initWithString:[currentFont displayName]];
		[fontSample appendAttributedString:fontName];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	/* if (aTableView == sizeListView) */

	ASSIGN(fontSize, [sizes objectAtIndex:rowIndex]);
	[self update];

	return YES;
}

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	/* if (aTableView == sizeListView) */
	return [sizes count];
}

- (id) tableView: (NSTableView *)aTableView
	objectValueForTableColumn: (NSTableColumn *)aTableColumn
             row: (int)rowIndex
{
	/* if (aTableView == sizeListView) */
	return [sizes objectAtIndex:rowIndex];
}

- (void) controlTextDidEndEditing: (NSNotification *)aNotification
{
	/* NSControlTextDidEndEditingNotification */
	
	ASSIGN(fontSize, [sizeField objectValue]);
	
	[self update];
}

@end
