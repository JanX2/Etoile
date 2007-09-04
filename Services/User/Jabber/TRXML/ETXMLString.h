//
//  ETXMLString.h
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETXMLNullHandler.h"

/**
 * The ETXMLString class parses XML elements of the form <element>some character
 * data</element>.  All child elements will be ignored, and the character data 
 * will be returned to the parent as an NSString.
 */
@interface ETXMLString : ETXMLNullHandler {
}
@end
