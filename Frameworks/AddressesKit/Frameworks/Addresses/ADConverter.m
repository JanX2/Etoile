// ADConverter.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:01 $

/* system includes */
/* (none) */

/* my includes */
#include "ADConverter.h"
#include "ADPListConverter.h"
#include "ADVCFConverter.h"

ADConverterManager *_manager = nil;

@implementation ADConverterManager
+ (ADConverterManager*) sharedManager
{
  if(!_manager)
    _manager = [[self alloc] init];
  return _manager;
}

- init
{
  _icClasses = [[NSMutableDictionary alloc] initWithCapacity: 1];
  _ocClasses = [[NSMutableDictionary alloc] initWithCapacity: 1];

  // couple of standard converters
  
  [self registerInputConverterClass: [ADPListConverter class]
	forType: @"mfaddr"];
  
  [self registerInputConverterClass: [ADVCFConverter class]
	forType: @"vcf"];
  [self registerOutputConverterClass: [ADVCFConverter class]
	forType: @"vcf"];

  return [super init];
}

- (BOOL) registerInputConverterClass: (Class) c
			     forType: (NSString*) type
{
  type = [type lowercaseString];
  if([[_icClasses allKeys] containsObject: type])
    return NO;

  [_icClasses setObject: c forKey: type];
  return YES;
}

- (BOOL) registerOutputConverterClass: (Class) c
			      forType: (NSString*) type
{
  type = [type lowercaseString];
  if([[_ocClasses allKeys] containsObject: type])
    return NO;

  [_ocClasses setObject: c forKey: type];
  return YES;
}

- (id<ADInputConverting>) inputConverterForType: (NSString*) type
{
  Class c;

  c = [_icClasses objectForKey: type];
  if(!c) return nil;
  return [[[c alloc] initForInput] autorelease];
}

- (id<ADOutputConverting>) outputConverterForType: (NSString*) type
{
  Class c;

  c = [_ocClasses objectForKey: type];
  if(!c) return nil;
  return [[[c alloc] initForOutput] autorelease];
}

- (id<ADInputConverting>) inputConverterWithFile: (NSString*) filename
{
  id<ADInputConverting> obj;
  Class c;

  c = [_icClasses objectForKey: [[filename pathExtension]
				  lowercaseString]];
  if(!c) return nil;

  obj = [[[c alloc] initForInput] autorelease];
  if(![obj useString: [NSString stringWithContentsOfFile: filename]])
    return nil;

  return obj;
}

- (NSArray*) inputConvertableFileTypes
{
  return [_icClasses allKeys];
}
  
- (NSArray*) outputConvertableFileTypes
{
  return [_ocClasses allKeys];
}

@end
