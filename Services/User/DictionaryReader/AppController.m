/*
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>

#import "AppController.h"
#import "GNUstep.h"

#import "DictConnection.h"
#import "NSString+Clickable.h"

NSDictionary* bigHeadlineAttributes;
NSDictionary* headlineAttributes;
NSDictionary* normalAttributes;


@implementation AppController (HistoryManagerDelegate)

-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation {
  if ([[aLocation class] isSubclassOfClass: [NSString class]]) {
    [self defineWord: (NSString*) aLocation];
  }
  
  return YES;
}

@end

@implementation AppController (DefinitionWriter)

-(void) clearResults
{
  NSAttributedString* emptyAttrStr = [[NSAttributedString alloc] init];
  [[searchResultView textStorage] setAttributedString: emptyAttrStr];
  [emptyAttrStr release];
}

-(void) writeString: (NSString*) aString
	 attributes: (NSDictionary*) attributes
{
  NSAttributedString* attrStr =
    [[NSAttributedString alloc]
      initWithString: aString
      attributes: attributes];
  [[searchResultView textStorage] appendAttributedString: attrStr];
  [attrStr release];
  
  // Tell the search result view to scroll to the top,
  // select nothing and redraw
  [searchResultView scrollRangeToVisible: NSMakeRange(0.0,0.0)];
  [searchResultView setSelectedRange: NSMakeRange(0.0,0.0)];
  [searchResultView setNeedsDisplay: YES];
}

-(void) writeBigHeadline: (NSString*) aString {
  [self writeString: [NSString stringWithFormat: @"\n%@\n", aString]
	attributes: bigHeadlineAttributes];
}

-(void) writeHeadline: (NSString*) aString {
  [self writeString: [NSString stringWithFormat: @"\n%@\n\n", aString]
	attributes: headlineAttributes];
}

-(void) writeLine: (NSString*) aString {
  // the index of the next character to write
  unsigned index = 0;
  unsigned strLength = [aString length];
  
  // YES if and only if we are inside a link
  BOOL inLink = NO;
  
  unsigned nextBracketIdx;
  
  while (index < strLength) {
    if (inLink == YES) {
      nextBracketIdx = [aString firstIndexOf: (unichar)'}'
				fromIndex: index];
      
      if (nextBracketIdx == -1) {
	// treat as if the next bracket started right after the
	// last character in the string
	nextBracketIdx = strLength;
	
	// FIXME: Handle multiline links, too!
	NSLog(@"multiline link detected!");
      }
      
      // crop text out of the input string
      NSString* linkContent =
	[aString substringWithRange: NSMakeRange(index, nextBracketIdx-index)];
      
      // next index is right after the found bracket
      index = nextBracketIdx + 1;
      
      // we're not in the link any more
      inLink = NO;
      
      // write link!
      [self writeString: linkContent
	    link: linkContent];
      
    } else { // inLink == FALSE
      nextBracketIdx = [aString firstIndexOf: (unichar)'{'
				fromIndex: index];
      
      if (nextBracketIdx == -1) {
	// treat as if the next bracket was right after the
	// last character in the string
	nextBracketIdx = strLength;
      }
      
      // crop text
      NSString* text =
	[aString substringWithRange: NSMakeRange(index, nextBracketIdx-index)];
      
      // proceed right after the bracket
      index = nextBracketIdx + 1;
      
      // now we're in a link
      inLink = YES;
      
      // write text!
      [self writeString: text
	    attributes: normalAttributes];
      
    } // end if(inLink)
    
  } // end while(index < strLength)
  
  
  // after everything is done, write a newline!
  [self writeString: @"\n"
	attributes: normalAttributes];
  
}

-(void) writeString: (NSString*) aString
	       link: (id) aClickable
{
  // fall back to 'no link'
  NSDictionary* attributes = normalAttributes;
  
  // if it's a valid link, use special attributes!
  if ([aClickable respondsToSelector: @selector(click)]) {
    attributes =
      [NSDictionary dictionaryWithObjectsAndKeys:
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
  [self writeString: aString
	attributes: attributes];
}

@end // AppController (DefinitionWriter)


// FIXME: Just for clean programming style: dealloc is missing,
//        but I think it's not needed.

@implementation AppController

-(id)init
{
  if (self = [super init]) {
    dict = [[DictConnection alloc] init];
    [dict setDefinitionWriter: self];
    
    historyManager = [[HistoryManager alloc] init];
    [historyManager setDelegate: self];
  }
  
  if (bigHeadlineAttributes == nil) {
    bigHeadlineAttributes = 
      [[NSDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont titleBarFontOfSize: 16], NSFontAttributeName,
	nil
       ];
  }
  
  if (headlineAttributes == nil) {
    headlineAttributes = 
      [[NSDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont boldSystemFontOfSize: 12], NSFontAttributeName,
	nil
       ];
  }
  
  if (normalAttributes == nil) {
    normalAttributes = 
      [[NSDictionary alloc]
	initWithObjectsAndKeys:
	  [NSFont userFixedPitchFontOfSize: 10], NSFontAttributeName,
	nil
       ];
  }
  
  // Register in the default notification center to receive link clicked events
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(clickSearchNotification:)
    name: WordClickedNotificationType
    object: nil];
  
  return self;
}


// ---- Some methods called by the GUI
-(void) browseBackClicked: (id)sender {
  [historyManager browseBack];
}

-(void) browseForwardClicked: (id)sender {
  [historyManager browseForward];
}

-(void)updateGUI {
  if ([historyManager canBrowseBack]) {
    [browseBackButton setEnabled: YES];
    [browseBackButton setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
  } else { // cannot browse back
    [browseBackButton setEnabled: NO];
    [browseBackButton setImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
  }
  [browseBackButton setNeedsDisplay: YES];
  
  if ([historyManager canBrowseForward]) {
    [browseForwardButton setEnabled: YES];
    [browseForwardButton setImage: [NSImage imageNamed: @"common_ArrowRight"]];
  } else { // cannot browse forward
    [browseForwardButton setEnabled: NO];
    [browseForwardButton setImage: [NSImage imageNamed: @"common_ArrowRightH"]];
  }
  [browseForwardButton setNeedsDisplay: YES];
}


// ---- This object is the delegate for the result view, too.
-(BOOL) textView: (NSTextView*) textView
   clickedOnLink: (id) link
	 atIndex: (unsigned) charIndex
{
  if ([link respondsToSelector: @selector(click)]) {
    
    NS_DURING
      {
	[link click];
      }
    NS_HANDLER
      {
	NSRunAlertPanel(@"Link click failed!",
			[localException reason],
			@"Oh no!", nil, nil);
	return NO;
      }
    NS_ENDHANDLER;
    
    return YES;
  } else {
    NSLog(@"Link %@ clicked, but it doesn't respond to 'click'", link);
    return NO;
  }
}


// ---- Searching

/**
 * Responds to a search action invoked from the GUI by clicking the
 * search button or hitting enter when the search field is focused.
 */
-(void)searchAction: (id)sender
{
  // define the word that's written in the search field
  [self defineWord: [searchStringControl stringValue]];
}

/**
 * Responds to a search action invoked by clicking a word
 * reference in the text view.
 */
-(void)clickSearchNotification: (NSNotification*)aNotification
{
  assert(aNotification != nil);
  
  // fetch string from notification
  NSString* searchString = [aNotification object];
  
  assert(searchString != nil);
  
  if ( ![[searchStringControl stringValue] isEqualToString: searchString] ) {
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
-(void)defineWord: (NSString*)aWord
{
  if ( ![[searchStringControl stringValue] isEqualToString: aWord] ) {
    // set string in search field
    [searchStringControl setStringValue: aWord];
  }
  
  NS_DURING
    {
      [dict open];
      [dict sendClientString: @"GNUstep DictionaryReader.app"];
      [dict definitionFor: aWord];
      // [dict close]; // FIXME: That crashes!
      
      [historyManager browser: self
		      didBrowseTo: aWord];
      [self updateGUI];
    }
  NS_HANDLER
    {
      NSRunAlertPanel
	(
	 @"Word definition failed.",
	 [NSString
	   stringWithFormat:
	     @"The definition of %@ failed because of this exception:\n%@",
	   aWord, [localException reason]],
	 @"Argh", nil, nil);
    }
  NS_ENDHANDLER;
}

@end // AppController
