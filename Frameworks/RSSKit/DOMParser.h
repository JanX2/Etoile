// -*-objc-*-

#import <Foundation/Foundation.h>

@protocol XMLTextOrNode;
@class XMLNode;

@protocol XMLTextOrNode <NSObject>
-(NSString*) contentAndNextContents;
-(NSString*) content;
-(void) _setNext: (id<XMLTextOrNode>) node;
-(XMLNode*) nextElement;
@end

@interface XMLText : NSObject <XMLTextOrNode>
{
  NSString* _content;
  id<XMLTextOrNode> _next;
}

-(NSString*) contentAndNextContents;
-(NSString*) content;
-(void) _setNext: (id<XMLTextOrNode>) node;
-(XMLNode*) nextElement;

-(id)init;
-(id)initWithString: (NSString*) str;

-(void)dealloc;
@end


@interface XMLNode : NSObject <XMLTextOrNode>
{
  NSString* _name;
  NSString* _namespace;
  
  XMLNode* _child;
  id<XMLTextOrNode> _next;
  
  id<XMLTextOrNode> _current;
  XMLNode* _parent;
  
  NSDictionary* _attributes;
}

-(XMLNode*) firstChildElement;

-(XMLNode*) nextElement;

-(NSString*) name;

-(NSString*) contentAndNextContents;
-(NSString*) content;

-(NSDictionary*) attributes;

-(NSString*) namespace;

-(id) initWithName: (NSString*) name
	 namespace: (NSString*) namespace
	attributes: (NSDictionary*) attributes
	    parent: (XMLNode*) parent;

-(void) dealloc;

- (void) _setNext: (id <XMLTextOrNode>) node;

- (void) appendTextOrNode: (id<XMLTextOrNode>) aThing
	       fromParser: (NSXMLParser*) aParser;

@end

@interface XMLNode (NSXMLParserDelegateEventAdditions)
- (void) parser: (NSXMLParser*)aParser
  didEndElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName;

- (void) parser: (NSXMLParser*)aParser
didStartElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName
     attributes: (NSDictionary*)anAttributeDict;

- (void)    parser: (NSXMLParser*)aParser
 parseErrorOccured: (NSError*)parseError;

- (void) parser: (NSXMLParser*)aParser
foundCharacters: (NSString*)aString;

@end
