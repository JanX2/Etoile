/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "DictionaryHandle.h"
#import "GNUstep.h"

@implementation DictionaryHandle

+ (id) dictionaryFromPropertyList: (NSDictionary*) aPropertyList
{
    DictionaryHandle *dict = nil;
	Class dictClass = NSClassFromString([aPropertyList objectForKey: @"class"]);
	dict = [[dictClass alloc] initFromPropertyList: aPropertyList];
	return AUTORELEASE(dict);
}

- (id) initFromPropertyList: (NSDictionary*) aPropertyList
{
    NSAssert([self class] != [DictionaryHandle class],
        @"DictionaryHandle is abstract, don't instantiate it directly!"
    );
    
    if ((self = [self init]) != nil) 
	{
        [self setActive: [[aPropertyList objectForKey: @"active"] intValue]];
    }
    
    return self;
}

- (void) dealloc
{
	DESTROY(defWriter);
	[super dealloc];
}

- (void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter
{
    NSAssert1(aDefinitionWriter != nil,
              @"-setDefinitionWriter: parameter must not be nil in %@", self);
    ASSIGN(defWriter, aDefinitionWriter);
}

- (NSDictionary*) shortPropertyList
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: 4];
    
    [dict setObject: NSStringFromClass([self class]) forKey: @"class"];
    [dict setObject: [NSNumber numberWithBool: _active] forKey: @"active"];
    
    return dict;
}

- (BOOL) isActive
{
    return _active;
}

- (void) setActive: (BOOL) isActive
{
    _active = isActive;
}

- (void) showError: (NSString *) aString
{
	[defWriter writeBigHeadline: [NSString stringWithFormat: @"%@ Error", self]];
	[defWriter writeLine: aString];
}

- (void) log: (NSString *) aLogMsg
{
	NSLog(@"%@", aLogMsg);
}

- (void) handleDescription
{
	// Do nothing
}

- (void) descriptionForDatabase: (NSString *) aDatabase
{
	// Do nothing
}

- (void) definitionFor: (NSString *) aWord
{
	// Do nothing
}

- (void) definitionFor: (NSString *) aWord inDictionary: (NSString *) aDict
{
	// Do nothing
}

- (void) open
{
	// Do nothing
}

- (void) close
{
	// Do nothing
}

@end
