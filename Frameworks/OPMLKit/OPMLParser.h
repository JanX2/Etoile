/*
 * Created by guenther on 2006-11-21 20:47:43 +0000
 * All Rights Reserved
 */

#ifndef _OPMLPARSER_H_
#define _OPMLPARSER_H_

#import <Foundation/Foundation.h>
#import "OPMLOutline.h"
#import "OPMLDocument.h"

@interface OPMLParser : NSObject
{
  // Just for parsing
  int parserState;
  int unknownTagNesting;
  OPMLOutline* currentOutline;
  OPMLDocument* document;
  
  NSMutableString* characters;
}


+(OPMLParser*) shared;


// Parsing

-(OPMLDocument*) parseData: (NSData*) theData;
-(OPMLDocument*) parseData: (NSData*) theData intoDocument: (OPMLDocument*) aDocument;

@end

#endif // _OPMLPARSER_H_
