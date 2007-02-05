//
//  TRXMLXHTML-IMParser.h
//  Jabber
//
//  Created by David Chisnall on 16/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TRXML/TRXMLNullHandler.h"

@interface TRXMLXHTML_IMParser : TRXMLNullHandler {
	NSMutableDictionary * currentAttributes;
	NSMutableArray * attributeStack;
	NSMutableAttributedString * string;
}

@end
