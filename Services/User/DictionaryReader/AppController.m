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

#import "AppController.h"
#import <AppKit/AppKit.h>

#import "DictConnection.h"

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

-(void) writeLine: (NSString*) aString
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
  [self writeLine: [NSString stringWithFormat: @"\n%@\n", aString]
	attributes: bigHeadlineAttributes];
}

-(void) writeHeadline: (NSString*) aString {
  [self writeLine: [NSString stringWithFormat: @"\n%@\n\n", aString]
	attributes: headlineAttributes];
}

-(void) writeLine: (NSString*) aString {
  [self writeLine: [NSString stringWithFormat: @"%@\n", aString]
	attributes: normalAttributes];
}

@end

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
  return self;
}

-(void)searchAction: (id)sender
{
  NSString* searchString = [searchStringControl stringValue];
  
  [dict open];
  [dict sendClientString: @"GNUstep DictionaryReader.app"];
  [dict definitionFor: searchString];
  // [dict close]; // FIXME: That crashes!
}

@end
