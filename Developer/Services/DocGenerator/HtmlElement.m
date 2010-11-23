//
//  HtmlElement.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HtmlElement.h"

@interface BlankHTMLElement : HtmlElement 
@end

@implementation BlankHTMLElement

- (NSString *) content
{
	return @"";
}

@end


@implementation HtmlElement

+ (HtmlElement *) blankElement
{
	return AUTORELEASE([[BlankHTMLElement alloc] initWithName: @"Blank"]);
}

+ (HtmlElement*) elementWithName: (NSString*) aName
{
  HtmlElement* elem = [[HtmlElement alloc] iniWithName: aName];
  return [elem autorelease];
}

- (HtmlElement*) iniWithName: (NSString*) aName
{
  self = [super init];
  children = [NSMutableArray new];
  attributes = [NSMutableDictionary new];
  elementName = [[NSString alloc] initWithString: aName];
  return self;
}

- (void) dealloc
{
  [children release];
  [attributes release];
  [elementName release];
  [super dealloc];
}

- (HtmlElement*) addText: (NSString*) aText
{
  if (aText)
    [children addObject: aText];
  return self;
}

- (HtmlElement*) add: (HtmlElement*) anElem 
{
  if (anElem)
    [children addObject: anElem];
  return self;
}

- (HtmlElement*) id: (NSString*) anID
{
  if (anID)
    [attributes setObject: anID forKey: @"id"];
  return self;
}

- (HtmlElement*) class: (NSString*) aClass
{
  if (aClass)
    [attributes setObject: aClass forKey: @"class"];
  return self;
}

- (HtmlElement*) name: (NSString*) aName
{
  if (aName)
    [attributes setObject: aName forKey: @"name"];
  return self;
}

/*
 forwarding...
 */

- (NSMethodSignature*) methodSignatureForSelector: (SEL) aSelector
{
  NSString* sig = NSStringFromSelector(aSelector);
//  NSLog (@"methodSignature for selector <%@>", sig);
  NSArray* components = [sig componentsSeparatedByString: @":"];
  NSMutableString* signature = [NSMutableString stringWithString: @"@@:"];
  for (int i=0; i<[components count]; i++)
  {
    NSString* component = [components objectAtIndex: i];
    if ([component length] > 0) 
    {
//      NSLog (@"component <%@>", component);
      [signature appendString: @"@"];
    }
  }
//  NSLog (@"generated sig <%@> for sel<%@>", signature, sig);
  return [NSMethodSignature signatureWithObjCTypes: [signature UTF8String]];
}

#define CALLM(assig,asig)\
  if ([component isEqualToString: assig])\
  {\
    id arg;\
    [invocation getArgument: &arg atIndex: i+2];\
    [self asig: arg];\
  }

- (void) forwardInvocation: (NSInvocation*) invocation
{
//  NSLog (@"invocation called <%@>", NSStringFromSelector([invocation selector]));
  NSString* sig = NSStringFromSelector([invocation selector]);
  NSArray* components = [sig componentsSeparatedByString: @":"];
  for (int i=0; i<[components count]; i++)
  {
    NSString* component = [components objectAtIndex: i];
    if ([component length] > 0) 
    {
//      NSLog (@"component <%@>", component);
      CALLM(@"id",id)
      CALLM(@"class",class)
      CALLM(@"with",with)
      CALLM(@"and",and)
    }
  }
//  NSLog (@"after invocation of <%@>:\n%@", sig, [self content]);
  [invocation setReturnValue: &self];
}

/*
 convenient functions...
 */

- (HtmlElement*) with: (id) something
{
  if ([something isKindOfClass: [NSString class]])
  {
    return [self addText: something];
  } 
  else
  {
    return [self add: something];
  }
}

- (HtmlElement*) and: (id) something
{
  return [self with: something];
}

- (NSString*) content
{
  NSMutableString* buf = [NSMutableString new];
  [buf appendFormat: @"<%@", elementName];
  NSArray* keys = [attributes allKeys];
  for (int i=0; i<[keys count]; i++)
  {
    NSString* key = [keys objectAtIndex: i];
    [buf appendFormat: @" %@=\"%@\"", key, [attributes objectForKey: key]];
  }
  [buf appendString: @">"];
  
  for (int i=0; i<[children count]; i++)
  {
    id elem = [children objectAtIndex: i];
    if ([elem isKindOfClass: [HtmlElement class]])
    {
      [buf appendString: [elem content]];
    }
    else if ([elem isKindOfClass: [NSString class]]) 
    {
      [buf appendString: elem];
    }
    else 
    {
      [buf appendString: [elem description]];
    }
  }
  [buf appendFormat: @"</%@>\n", elementName];
  return [buf autorelease];
}

- (NSString *) description
{
	return [self content];
}

@end
