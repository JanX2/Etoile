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
  [self writeString: [NSString stringWithFormat: @"%@\n", aString]
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


// ---- This is the delegate for the result view, too.
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
    // set string in search field
    [searchStringControl setStringValue: searchString];
    
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
  NS_DURING
    {
      [dict open];
      [dict sendClientString: @"GNUstep DictionaryReader.app"];
      [dict definitionFor: aWord];
      // [dict close]; // FIXME: That crashes!
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
