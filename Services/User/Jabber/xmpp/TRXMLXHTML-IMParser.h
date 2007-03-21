//
//  TRXMLXHTML-IMParser.h
//  Jabber
//
//  Created by David Chisnall on 16/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TRXMLNullHandler.h"

/**
 * The TRXMLXHTML_IMParser class constructs an NSAttributedString from a series of
 * XHTML-IM tags handed to the parser.  
 *
 * Not yet finished.
 */
@interface TRXMLXHTML_IMParser : TRXMLNullHandler {
	NSMutableDictionary * currentAttributes;
	NSMutableArray * attributeStack;
	NSMutableAttributedString * string;
}

@end
