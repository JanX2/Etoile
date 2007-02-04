/*
 * Created by guenther on 2006-11-21 20:47:43 +0000
 * All Rights Reserved
 */

#import <Foundation/Foundation.h>
#import "OPMLParser.h"


/*
 * OPML Parser states
 *                          .-> InHead <-.
 *                         /     / \      \
 *   *START*              /     /   \      \
 *  NotParsed -----> InRoot <--<     '--> InHeaderEntry
 *                    /  \      \
 *         *END*     /    \      \
 *        Parsed <--'      '-> InBody <-.
 *                                \      \
 *                                 \      \
 *                                  '--> InOutline
 */
enum OPMLDocumentParserState
{
    NotParsedState,
    InRootState,
    InHeadState,
    InHeaderEntryState,
    InBodyState,
    InOutlineState,
    ParsedState
};


@implementation OPMLParser


// ------------------------------------------------------------------------
//    singleton stuff
// ------------------------------------------------------------------------

+(OPMLParser*) shared
{
    static OPMLParser* singleton = nil;
    if (singleton == nil) {
        singleton = [[self alloc] init];
    }
    return singleton;
}


// -----------------------------------------------------------------
//    The parse method(s) itself
// -----------------------------------------------------------------

-(OPMLDocument*)parseData: (NSData*) theData;
{
    return [self parseData: theData intoDocument: [OPMLDocument new]];
}

-(OPMLDocument*)parseData: (NSData*) theData intoDocument: (OPMLDocument*) aDocument;
{
    NSXMLParser* parser = [[[NSXMLParser alloc] initWithData: theData] autorelease];
    
    [parser setDelegate: self];
    [parser setShouldProcessNamespaces: YES];
    
    parserState = NotParsedState;
    unknownTagNesting = 0;
    DESTROY(currentOutline);
    ASSIGN(self->document, aDocument);
    
    if ([parser parse] == NO || parserState != ParsedState) {
        /* in this case, either the XML parsing failed or
           the OPML structure was not found in it, in which
           case the parser is not in ParsedState afterwards. */
        DESTROY(self->document);
        return nil;
    } else {
        DESTROY(self->document);
        return aDocument;
    }
}



// ------------------------------------------------------------------
//    Handling the finding of header information
// ------------------------------------------------------------------

-(void) foundTitle: (NSString*) aTitle
{
    [document setTitle: [NSString stringWithString: aTitle]];
}

-(void) foundOwnerName: (NSString*) anOwnerName
{
    [document setOwnerName: [NSString stringWithString: anOwnerName]];
}

-(void) foundOwnerEmail: (NSString*) anOwnerEmail
{
    [document setOwnerEmail: [NSString stringWithString: anOwnerEmail]];
}

// ------------------------------------------------------------------
//    NSXMLParser delegate methods
// ------------------------------------------------------------------

- (void) parser: (NSXMLParser*)aParser
  didEndElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName
{
    if (unknownTagNesting > 0) {
        unknownTagNesting--;
    } else {
        switch (parserState) {
            case InRootState:
                if ([anElementName isEqualToString: @"opml"]) {
                    parserState = ParsedState;
                }
                break;
                
            case InHeadState:
                if ([anElementName isEqualToString: @"head"]) {
                    parserState = InRootState;
                }
                break;
                
            case InHeaderEntryState:
                if ([anElementName isEqualToString: @"title"]) {
                    [self foundTitle: self->characters];
                } else if ([anElementName isEqualToString: @"ownerName"]) {
                    [self foundOwnerName: self->characters];
                } else if ([anElementName isEqualToString: @"ownerEmail"]) {
                    [self foundOwnerEmail: self->characters];
                }
                parserState = InHeadState;
                break;
                
            case InBodyState:
                if ([anElementName isEqualToString: @"body"]) {
                    parserState = InRootState;
                }
                break;
                
            case InOutlineState:
                if ([anElementName isEqualToString: @"outline"]) {
                    if ([[self->currentOutline parent] isKindOfClass: [OPMLOutline class]]) {
                        parserState = InOutlineState;
                        ASSIGN(self->currentOutline, [self->currentOutline parent]);
                    } else {
                        parserState = InBodyState;
                        DESTROY(self->currentOutline);
                    }
                }
                break;
                
                
            default:
                [NSException raise: @"OPML parsing error"
                            format: @"Wrong state (%d) when tag %@ closed.", parserState, anElementName];
                break;
        }
    }
}


- (void) parser: (NSXMLParser*)aParser
didStartElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName
     attributes: (NSDictionary*)anAttributeDict
{
    if (unknownTagNesting > 0) {
        unknownTagNesting++;
        return;
    }
    
    enum OPMLDocumentParserState newParserState = -1;
    
    switch (parserState) {
        case NotParsedState:
            if ([anElementName isEqualToString: @"opml"]) {
                newParserState = InRootState;
            }
            break;
        
        case InRootState:
            if ([anElementName isEqualToString: @"head"]) {
                newParserState = InHeadState;
            } else if ([anElementName isEqualToString: @"body"]) {
                newParserState = InBodyState;
            }
            break;
        
        case InHeadState:
            if ([anElementName isEqualToString: @"title"] ||
                [anElementName isEqualToString: @"ownerName"] ||
                [anElementName isEqualToString: @"ownerEmail"]) {
                newParserState = InHeaderEntryState;
                ASSIGN(self->characters, [NSMutableString new]);
            }
            break;
        
        case InBodyState:
            NSLog(@"InBodyState, finding an outline");
            if ([anElementName isEqualToString: @"outline"]) {
                newParserState = InOutlineState;
                ASSIGN(
                    self->currentOutline,
                    [OPMLOutline outlineWithAttributes: anAttributeDict
                                                 array: [NSArray new]]
                );
                [self->currentOutline setParent: self->document];
                [document appendOutline: self->currentOutline];
                NSAssert([document outlineCount] > 0, @"Document outline count is zero");
            }
            break;
            
        case InOutlineState:
            if ([anElementName isEqualToString: @"outline"]) {
                newParserState = InOutlineState;
                OPMLOutline* parentOutline = self->currentOutline;
                ASSIGN(
                    self->currentOutline,
                    [OPMLOutline outlineWithAttributes: anAttributeDict
                                                 array: [NSArray new]]
                );
                [self->currentOutline setParent: parentOutline];
                [parentOutline appendOutline: self->currentOutline];
            }
            break;
            
        default:
            [NSException raise: @"OPML Parsing error"
                        format: @"Wrong state (%d) when tag %@ opened.", parserState, anElementName];
            break;
    }
    
    if (newParserState == -1) {
        // something that we didn't recognise opened.
        unknownTagNesting++; // = 1
    } else {
        parserState = newParserState;
    }
}

- (void)    parser: (NSXMLParser*)aParser
 parseErrorOccured: (NSError*)parseError
{
    NSLog(@"PARSE ERROR * %@ *", parseError);
}

- (void) parser: (NSXMLParser*)aParser
foundCharacters: (NSString*)aString
{
    if (self->characters == nil) {
        ASSIGN(self->characters, [NSMutableString new]);
    }
    
    [self->characters appendString: aString];
}

@end
