//
//  TRXMLParser.h
//  Jabber
//
//  Created by David Chisnall on Wed Apr 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLParserDelegate.h"

@interface TRXMLParser : NSObject {
	NSMutableString * buffer;
	id <NSObject, TRXMLParserDelegate> delegate;
	int depth;
	NSMutableArray * openTags;
	enum {notag, intag, inattribute, incdata, instupidcdata, incomment, broken} state;
}
+ (id) parserWithContentHandler:(id <NSObject, TRXMLParserDelegate>) _contentHandler;
- (id) initWithContentHandler:(id <NSObject, TRXMLParserDelegate>) _contentHandler;
- (id) setContentHandler:(id <NSObject, TRXMLParserDelegate>) _contentHandler;
- (BOOL) parseFromSource:(NSString*) data;
@end
