//
//  TRXMLParserDelegate.h
//  Jabber
//
//  Created by David Chisnall on Wed Apr 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TRXMLParserDelegate
- (void)characters:(NSString *)_chars;
- (void)startElement:(NSString *)_Name
		  attributes:(NSDictionary*)_attributes;
- (void)endElement:(NSString *)_Name;
- (void) setParser:(id) XMLParser;
- (void) setParent:(id) newParent;
@end
