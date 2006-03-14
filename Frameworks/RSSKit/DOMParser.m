// -*-objc-*-

#import "DOMParser.h"


// #define DEBUG 1

@implementation XMLText

-(NSString*) contentAndNextContents
{
  return [NSString stringWithFormat: @"%@%@",
		   ( (_content==nil) ? @"" : _content ),
		   ( (_next==nil) ? @"" : [_next contentAndNextContents])];
}

-(NSString*) content
{
  return ( (_content==nil) ? @"" : _content );
}

-(void) _setNext: (id<XMLTextOrNode>) node
{
  ASSIGN(_next, node);
}

-(XMLNode*) nextElement
{
  // !!! If you change this, change it in XMLNode, too!
  // XXX: Write a macro
  
  // we only return *XML elements* here, *not* contents!
  if ([[_next class] isSubclassOfClass: [XMLText class]]) {
    return [_next nextElement];
  } else {				    
    return AUTORELEASE(RETAIN(_next));
  }  
}

/**
 * @deprecated
 * Please don't call init on XMLText objects. It won't work.
 * Instead, use initWithString:
 */
-(id)init
{
  [self release];
  return nil;
}

-(id)initWithString: (NSString*) str
{
  self = [super init];
  
  if (self != nil) {
    ASSIGN(_content, str);
  }
  
  return self;
}

-(void)dealloc
{
  RELEASE(_next);
  RELEASE(_content);
}

@end


@implementation XMLNode

-(XMLNode*) firstChildElement
{
  if (_child == nil)
    return nil;
  
  if ([[_child class] isSubclassOfClass: [XMLNode class]]) {
    return AUTORELEASE(RETAIN(_child));
  } else {
    return [_child nextElement];
  }
}

-(XMLNode*) nextElement
{
  // !!! If you change this, change it in XMLText, too!
  // XXX: Write a macro
  
  // we only return *XML elements* here, *not* contents!
  if ([[_next class] isSubclassOfClass: [XMLText class]]) {
    return [_next nextElement];
  } else {				    
    return AUTORELEASE(RETAIN(_next));
  }
}

-(NSString*) name
{
  return AUTORELEASE(RETAIN(_name));
}

-(NSString*) contentAndNextContents
{
  NSString* result;
  
  // XXX: attributes are still not shown here! Do we need it?
  
  if (_child == nil) {
    result = [NSString stringWithFormat:
			 @"<%@/>%@", _name,
		       (_next==nil?@"":[_next contentAndNextContents])];
  } else {
    result = [NSString stringWithFormat:
			 @"<%@>%@</%@>%@",
		       _name, [_child contentAndNextContents], _name,
		       (_next==nil?@"":[_next contentAndNextContents])];
  }
  
  return result;
}

-(NSString*) content
{
  NSString* result;
  
  // XXX: attributes are still not shown here! Do we need it?
  
  if (_child == nil) {
    result = @"";
  } else {
    result = [_child contentAndNextContents];
  }
  
  return result;
}

-(NSDictionary*) attributes
{
  return AUTORELEASE(RETAIN(_attributes));
}

-(NSString*) namespace
{
  return AUTORELEASE(RETAIN(_namespace));
}

-(id) initWithName: (NSString*) name
	 namespace: (NSString*) namespace
	attributes: (NSDictionary*) attributes
	    parent: (XMLNode*) parent;
{
  self = [super init];
  
  if (self != nil) {
    _name = RETAIN(name);
    _namespace = RETAIN(namespace);
    _parent = RETAIN(parent);
    _attributes = RETAIN(attributes);
  }
  
  return self;
}

-(void) dealloc
{
  RELEASE(_child);
  RELEASE(_next);
  RELEASE(_namespace);
  RELEASE(_name);
  RELEASE(_current);
  RELEASE(_parent);
  [super dealloc];
}

- (void) _setNext: (id<XMLTextOrNode>) node
{
  #ifdef DEBUG
  NSLog(@"_setNext: %@ --> %@", self, node);
  #endif

  ASSIGN(_next, node);
}


- (void) appendTextOrNode: (id<XMLTextOrNode>) aThing
	       fromParser: (NSXMLParser*) aParser
{
  NSLog(@"appendTextOrNode: %@ at: %@", aThing, [self name]);
  
  if (_child == nil) {
    _child = RETAIN(aThing);
  }
  
  if (_current == nil) {
    _current = RETAIN(aThing);
  } else {
    [_current _setNext: aThing];
    
    ASSIGN(_current, aThing);
  }
  
  if ([[aThing class] isSubclassOfClass: [XMLNode class]]) {
    [aParser setDelegate: aThing];
  }
}

@end

@implementation XMLNode (NSXMLParserDelegateEventAdditions)
- (void) parser: (NSXMLParser*)aParser
  didEndElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName
{
  #ifdef DEBUG
  NSLog(@"closing XML node %@", anElementName);
  #endif
  
  if (![anElementName isEqualToString: _name]) {
    NSLog(@"badly nested XML elements!");
  }
  
  if (_parent != nil) {
    [aParser setDelegate: _parent];
    RELEASE(_parent);
    _parent = nil;
  }
}

- (void) parser: (NSXMLParser*)aParser
didStartElement: (NSString*)anElementName
   namespaceURI: (NSString*)aNamespaceURI
  qualifiedName: (NSString*)aQualifierName
     attributes: (NSDictionary*)anAttributeDict
{
  XMLNode* item;
  
  item = [[XMLNode alloc]
	   initWithName: anElementName
	   namespace: aNamespaceURI
	   attributes: anAttributeDict
	   parent: self ];
  
  #ifdef DEBUG
  NSLog(@"starting XML node %@", anElementName);
  #endif
  
  [self appendTextOrNode: item
	fromParser: aParser];
  
  RELEASE(item);
}

- (void)    parser: (NSXMLParser*)aParser
 parseErrorOccured: (NSError*)parseError
{
  NSLog(@"XML-DOM Parser: %@ at line %@, col %@",
	[parseError localizedDescription],
	[aParser lineNumber], [aParser columnNumber]);
}

- (void) parser: (NSXMLParser*)aParser
foundCharacters: (NSString*)aString
{
  XMLText* text;
  text = [[XMLText alloc] initWithString: aString];
  
  [self appendTextOrNode: text
	fromParser: aParser];
  
  RELEASE(text);
}

@end
