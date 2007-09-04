//
//  NSAttributedString+HTML-IM.h
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ETXMLNode;
@interface NSAttributedString (XHTML_IM)
- (ETXMLNode*) xhtmlimValue;
- (NSString*) stringValueWithExpandedLinks;
@end
