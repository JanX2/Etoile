/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
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

#import "FeedParser.h"

@implementation FeedParser

// instantiation

+(id) parser
{
  return AUTORELEASE([[self alloc] init]);
}

+(id) parserWithDelegate: (id)aDelegate
{
  FeedParser* p = AUTORELEASE([[self alloc] init]);
  [p setDelegate: aDelegate];
  return p;
}

-(id) init
{
  if ((self = [super init]) != nil) {
    delegate = nil;
  }
  
  return self;
}

// parsing

-(void) parseWithRootNode: (XMLNode*) root
{
  NSLog(@"XXX: called -parseWithRootNode: in FeedParser. It should have been called in a subclass!");
}


//delegate

-(void) setDelegate: (id)aDelegate
{
  ASSIGN(delegate, aDelegate);
}

-(id) delegate
{
  return AUTORELEASE(RETAIN(delegate));
}


// helper methods

// FIXME: Do some HTML parsing here...
// Just a stub...
-(NSString*) stringFromHTMLAtNode: (XMLNode*) root
{
  return AUTORELEASE(RETAIN([root content]));
}

@end
