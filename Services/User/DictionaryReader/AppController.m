/*
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006, 2007 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>

#import "AppController.h"
#import "GNUstep.h"
#import "DictConnection.h"
#import "LocalDictionary.h"
#import "NSString+Clickable.h"
#import "Preferences.h"

NSDictionary* bigHeadlineAttributes;
NSDictionary* headlineAttributes;
NSDictionary* normalAttributes;

@interface AppController (DefinitionWriter)
- (void) writeString: (NSString*) aString
          attributes: (NSDictionary*) attributes;
- (void) writeString: (NSString*) aString link: (id) aClickable;
@end

@implementation AppController (HistoryManagerDelegate)

- (BOOL) historyManager: (HistoryManager *) aHistoryManager
         needsBrowseTo: (id) aLocation 
{
	if ([[aLocation class] isSubclassOfClass: [NSString class]]) 
	{
		[self defineWord: (NSString*) aLocation];
	}
  
	return YES;
}

@end

@implementation AppController (DefinitionWriter)

- (void) writeString: (NSString *) aString
          attributes: (NSDictionary*) attributes
{
	NSAttributedString* as = [[NSAttributedString alloc] initWithString: aString
	                                                    attributes: attributes];
	[[searchResultView textStorage] appendAttributedString: as];
	DESTROY(as);
  
	/* Tell the search result view to scroll to the top,
	   select nothing and redraw */
	[searchResultView scrollRangeToVisible: NSMakeRange(0.0,0.0)];
	[searchResultView setSelectedRange: NSMakeRange(0.0,0.0)];
	[searchResultView setNeedsDisplay: YES];
}


- (void) writeString: (NSString*) aString link: (id) aClickable
{
	// fall back to 'no link'
	NSDictionary* attributes = normalAttributes;
  
	// if it's a valid link, use special attributes!
	if ([aClickable respondsToSelector: @selector(click)]) 
	{
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		        // the link itself
		        aClickable, NSLinkAttributeName,
		        // font
		        [NSFont userFixedPitchFontOfSize: 10], NSFontAttributeName,
		        // underlining
		        [NSNumber numberWithInt: NSSingleUnderlineStyle],
		        NSUnderlineStyleAttributeName,
		        // color
		        [NSColor blueColor],
		        NSForegroundColorAttributeName,
		        nil];
	}
  
	// write
	[self writeString: aString attributes: attributes];
}

@end // AppController (DefinitionWriter)

@implementation AppController

- (id) init
{
	self = [super init];
	if (self == nil)
	{
		[self dealloc];
		return nil;
	}

	// create toolbar items
	forwardItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"Forward"];
	[forwardItem setImage: [NSImage imageNamed: @"etoile_forward"]];
	[forwardItem setAction: @selector(browseForwardClicked:)];
	[forwardItem setLabel: @"Forward"];
	[forwardItem setTarget: self];
	[forwardItem setEnabled: NO];
	
	backItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"Back"];
	[backItem setImage: [NSImage imageNamed: @"etoile_back"]];
	[backItem setAction: @selector(browseBackClicked:)];
	[backItem setLabel: @"Back"];
	[backItem setTarget: self];
	[backItem setEnabled: NO];

	searchItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"Search"];
	searchField = [[NSSearchField alloc] initWithFrame: NSMakeRect(0, 0, 150, 22)];
	[searchField setRecentsAutosaveName: @"recentDictionaryLookups"];
	[searchField setAction: @selector(searchAction:)];
	[[searchField cell] setSendsWholeSearchString: YES];
	[searchItem setView: searchField];
	[searchItem setLabel: @"Search"];
	[searchItem setMinSize: NSMakeSize(150, 22)];

	// create mutable dictionaries array
	dictionaries = [[NSMutableArray alloc] initWithCapacity: 2];

	// create history manager
	historyManager = [[HistoryManager alloc] init];
	[historyManager setDelegate: self];

    // create fonts
	if (bigHeadlineAttributes == nil) 
	{
		bigHeadlineAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		       [NSFont titleBarFontOfSize: 16], NSFontAttributeName, nil];
	}

	if (headlineAttributes == nil) 
	{
		headlineAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		       [NSFont boldSystemFontOfSize: 12], NSFontAttributeName, nil];
	}

	if (normalAttributes == nil) 
	{
		normalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		       [NSFont userFixedPitchFontOfSize: 10], NSFontAttributeName, nil];
	}

	// Notifications --------------
	NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];

	// Register in the default notification center to receive link clicked events
	[defaultCenter addObserver: self
	                  selector: @selector(clickSearchNotification:)
	                      name: WordClickedNotificationType
	                    object: nil];

    return self;
}

- (void) dealloc
{
	DESTROY(dictionaries);
	DESTROY(historyManager);
	DESTROY(backItem);
	DESTROY(forwardItem);
	DESTROY(searchItem);
	DESTROY(searchField);
	[super dealloc];
}

- (void) awakeFromNib 
{
	NSToolbar *toolbar = 
	  [[NSToolbar alloc] initWithIdentifier: @"DictionaryContentToolbar"];
	
	// create toolbar
	[toolbar setDelegate:self];
	
	[dictionaryContentWindow setToolbar:toolbar];
	DESTROY(toolbar);

	// find available dictionaries
	[[Preferences shared] setDictionaries: dictionaries];
	[[Preferences shared] rescanDictionaries: self];

// FIXME: Don't really know what to do with this code. May be useful for 
// debugging if -rescanDictionaries above is commented out. 
#ifdef PREDEFINED_DICTIONARIES // predefined dictionaries
	    // create local dictionary object
	    dict = [[LocalDictionary alloc] initWithResourceName: @"jargon"];
	    [dict setDefinitionWriter: self];
	    [dictionaries addObject: dict];
	    [dict release];
#ifdef REMOTE_DICTIONARIES // remote dictionaries
	    // create remote dictionary object
	    dict = [[DictConnection alloc] init];
	    [dict setDefinitionWriter: self];
	    [dictionaries addObject: dict];
	    [dict release];
#endif // end remote dictionaries block
#endif // end predefined dictionaries

}

// ---- Toolbar delegate methods

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString*) identifier
  willBeInsertedIntoToolbar: (BOOL) willBeInserted 
{
	NSToolbarItem* toolbarItem;
	if ([identifier isEqual: @"Back"]) 
	{
		toolbarItem = backItem;
	}
	else if ([identifier isEqual: @"Forward"]) 
	{
		toolbarItem = forwardItem;
	}
	else 
	{
		NSAssert1(
		  [identifier isEqual: @"Search"],
		  @"Bad toolbar item requested: %@", identifier
		);
		
		toolbarItem = searchItem;
	}
	
	NSAssert1(
		toolbarItem != nil,
		@"nil toolbar item returned for %@ identifier",
		identifier
	);

	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar 
{
	return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar 
{
	NSArray *identifiers = [NSArray arrayWithObjects: /*@"Back", @"Forward",*/ 
		NSToolbarFlexibleSpaceItemIdentifier, @"Search", nil];

	return identifiers;
}

// ---- Some methods called by the GUI
- (void) browseBackClicked: (id) sender 
{
	[historyManager browseBack];
}

- (void) browseForwardClicked: (id) sender 
{
	[historyManager browseForward];
}

- (void) orderFrontPreferencesPanel: (id)sender 
{
	[[Preferences shared] setDictionaries: dictionaries];
	[[Preferences shared] show];
}

- (void) updateGUI 
{
	[backItem setEnabled: [historyManager canBrowseBack]];
	[forwardItem setEnabled: [historyManager canBrowseForward]];
}


// ---- This object is the delegate for the result view, too.
- (BOOL) textView: (NSTextView*) textView clickedOnLink: (id) link
          atIndex: (unsigned) charIndex
{
	if ([link respondsToSelector: @selector(click)]) 
	{
		NS_DURING
			[link click];
		NS_HANDLER
			NSRunAlertPanel(@"Link click failed!", [localException reason],
		                    @"Oh no!", nil, nil);
			return NO;
		NS_ENDHANDLER;
    
		return YES;
	}
	else 
	{
		NSLog(@"Link %@ clicked, but it doesn't respond to 'click'", link);
		return NO;
	}
}


// ---- Searching

/**
 * Responds to a search action invoked from the GUI by clicking the
 * search button or hitting enter when the search field is focused.
 */
- (void) searchAction: (id) sender
{
	// define the word that's written in the search field
	[self defineWord: [searchField stringValue]];
}

/**
 * Responds to a search action invoked by clicking a word
 * reference in the text view.
 */
- (void) clickSearchNotification: (NSNotification*) not
{
	NSParameterAssert(not != nil);
  
	// fetch string from notification
	NSString* searchString = [not object];
  
	NSAssert1(
		searchString != nil,
		@"Search string encapsuled in %@ notification was nil", not 
	);
  
	if ( ![[searchField stringValue] isEqualToString: searchString] ) 
	{
		// invoke search
		[self defineWord: searchString];
	}
}

/**
 * Searches for definitions of the word given in the aWord
 * parameter and shows the results in the text view.
 * 
 * @param aWord the word to define
 */ 
- (void) defineWord: (NSString *) aWord
{
	if ( ![[searchField stringValue] isEqualToString: aWord] ) 
	{
		// set string in search field
		[searchField setStringValue: aWord];
	}
  
	// We need space for new content
	[self clearResults];
  
	// Iterate over all dictionaries, query them!
	int i;
  
	for (i = 0; i < [dictionaries count]; i++) 
	{
		id dict = [dictionaries objectAtIndex: i];
    
		if ([dict isActive]) 
		{
			NS_DURING
			{
				[dict open];
				//[dict sendClientString: @"GNUstep DictionaryReader.app"];
				[dict definitionFor: aWord];
				// [dict close];
			}
			NS_HANDLER
			{
				NSRunAlertPanel (
					@"Word definition failed.",
					[NSString stringWithFormat:
				@"The definition of %@ failed because of this exception:\n%@",
				 aWord, [localException reason]],
				@"Argh", nil, nil);
			}
			NS_ENDHANDLER;
		}
	}
  
	[historyManager browser: self didBrowseTo: aWord];
  
	[self updateGUI];
  
	[dictionaryContentWindow orderFront: self];
}

- (void) applicationWillTerminate: (NSNotification*) theNotification
{
	int i;
	NSMutableArray* mut = [NSMutableArray arrayWithCapacity: [dictionaries count]];
    
	for (i = 0; i < [dictionaries count]; i++) 
	{
		[mut addObject: [[dictionaries objectAtIndex: i] shortPropertyList]];
	}
    
	[mut writeToFile: [[Preferences shared] dictionaryStoreFile] atomically: YES];
}

- (void) applicationDidFinishLaunching: (NSNotification *) theNotification
{
	[NSApp setServicesProvider: self];
}

- (void) applicationDidBecomeActive: (NSNotification *) aNotification
{
	// show dictionary window when clicking the app icon
	[dictionaryContentWindow makeKeyAndOrderFront: self];
}

/**
 * The Dictionary Lookup service:
 * Takes a string from the calling application and looks it up.
 * Written by Chris B. Vetter
 */
- (void) lookupInDictionary: (NSPasteboard *) pboard
                   userData: (NSString *) userData
                      error: (NSString **) error
{
	NSString *aString = nil;
	NSArray *allTypes = nil;
  
	allTypes = [pboard types];
  
	if ( ![allTypes containsObject: NSStringPboardType] )
	{
		*error = @"No string type supplied on pasteboard";
		return;
	}
  
	aString = [pboard stringForType: NSStringPboardType];
  
	if (aString == nil)
	{
		*error = @"No string value supplied on pasteboard";
		return;
	}
  
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	[runLoop performSelector: @selector(defineWord:)
	                  target: self
	                argument: aString
	                   order: 1 //whatever
	                   modes: [NSArray arrayWithObject: [runLoop currentMode]]];
}

/* Definition Writer Protocol */
- (void) clearResults
{
	[searchResultView setString: @""];
}

- (void) writeBigHeadline: (NSString *) aString 
{
	[self writeString: [NSString stringWithFormat: @"\n%@\n", aString]
	       attributes: bigHeadlineAttributes];
}

- (void) writeHeadline: (NSString *) aString 
{
	[self writeString: [NSString stringWithFormat: @"\n%@\n\n", aString]
           attributes: headlineAttributes];
}

- (void) writeLine: (NSString *) aString 
{
	// the index of the next character to write
	unsigned index = 0;
	unsigned strLength = [aString length];

	// YES if and only if we are inside a link
	BOOL inLink = NO;
  
	unsigned nextBracketIdx;
  
	while (index < strLength) 
	{
		if (inLink == YES) 
		{
			nextBracketIdx = [aString firstIndexOf: (unichar)'}'
			                             fromIndex: index];
      
			if (nextBracketIdx == NSNotFound) 
			{
				/* treat as if the next bracket started right after the
				   last character in the string */
				nextBracketIdx = strLength;
	
				// FIXME: Handle multiline links, too!
				NSLog(@"multiline link detected!");
			}
      
			// crop text out of the input string
			NSString* linkContent = [aString substringWithRange: NSMakeRange(index, nextBracketIdx-index)];
      
			// next index is right after the found bracket
			index = nextBracketIdx + 1;
      
			// we're not in the link any more
			inLink = NO;
      
			// write link!
			[self writeString: linkContent link: linkContent];
		}
		else 
		{ // inLink == FALSE
			nextBracketIdx = [aString firstIndexOf: (unichar)'{'
			                             fromIndex: index];
      
			if (nextBracketIdx == NSNotFound) 
			{
				/* treat as if the next bracket was right after the
				   last character in the string */
				nextBracketIdx = strLength;
			}
      
			// crop text
			NSString* text = [aString substringWithRange: NSMakeRange(index, nextBracketIdx-index)];
      
			// proceed right after the bracket
			index = nextBracketIdx + 1;
      
			// now we're in a link
			inLink = YES;
      
			// write text!
			[self writeString: text attributes: normalAttributes];
		} // end if(inLink)
    
	} // end while(index < strLength)
  
	// after everything is done, write a newline!
	[self writeString: @"\n" attributes: normalAttributes];
}

@end

