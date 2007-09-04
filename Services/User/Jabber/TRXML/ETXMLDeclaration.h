//
//  TRXMLDeclaration.h
//  Jabber
//
//  Created by Yen-Ju Chen on Thu Jul 12 2007.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "TRXMLNode.h"

/**
 * The TRXMLDeclaration is a TRXMLNode representing the XML header 
 * in a form of <?xml version="1.0" encoding="UTF-8" ?>.
 * It only take attributes of 'version', 'encoding', 'standalone'
 * and without any CDATA.
 * 
 * NOTE: TRXMLParser does not generate TRXMLDeclaration node.
 * This node is only used for build TRXMLNode tree
 * and write out a string of XML document or serves as a root 
 * for TRXMLParser.
 */

@interface TRXMLDeclaration: TRXMLNode

/* Return a node representing <?xml version="1.0" encoding="UTF-8" ?> */
+ (id) TRXMLDeclaration;

@end

