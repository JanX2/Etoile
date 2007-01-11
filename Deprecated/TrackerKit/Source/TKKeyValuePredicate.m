/*
	TKKeyValuePredicate.m

	TKKeyValuePredicate is TrackerKit class used to encode the special keys
    which drive track sessions
	
	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
  

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2004

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/Foundation.h>
#import "TKKeyValuePredicate.h"


@implementation TKKeyValuePredicate /* Light ordered dictionary */

- (id) initWithIdentifier: (NSString *)identifier
{
    if ((self = [super init]) != nil)
    {
        ASSIGN(_identifier, identifier);
        _keyValue = [[NSMutableArray alloc] init];
       
        return self;
    }
    
    return nil;
}

- (id) initWithIdentifier: (NSString *)identifier 
             keyValuePath: (NSString *)keyValuePath
{
    // not implemented
} 

- (void) dealloc
{
    RELEASE(_keyValue);
    [super dealloc];
}

- (void) addValue: (NSString *)value forKeyComponent: (NSString *)keyComponent
{
    NSArray *component;
  
    if (keyComponent == nil)
    {
        [NSException raise: NSInvalidArgumentException
            format: @"Nil keyComponents are not valid."];
    }
    component = [NSArray arrayWithObjects: keyComponent, value];
    [_keyValue addObject: component];
}

- (void) addValues: (NSArray *)values 
        forKeyComponent: (NSString *)keyComponent;
{
    NSMutableArray *component;
  
    if (keyComponent == nil)
    {
        [NSException raise: NSInvalidArgumentException
            format: @"Nil keyComponents are not valid."];
    }
    component = [NSMutableArray arrayWithObjects: keyComponent, nil];
    [component addObjectsFromArray: values]; 
    [_keyValue addObject: component];
}

- (NSString *) identifier
{
    return _identifier;
}

- (id) componentAtIndex: (unsigned int)index
{
    return [_keyValue objectAtIndex: index];
}

- (NSString *) keyValuePath
{
  // not implemented -- called by description method
}

- (NSString *) keyPath
{
    NSEnumerator *e = [_keyValue objectEumerator];
    NSArray *component;
    NSMutableString *keyPath = [NSMutableString stringWithCapacity: 150];

    while ((component = [e nextObject]) != nil)
    {
        [keyPath appendString: [component objectAtIndex: 0]];
        [keyPath appendString: @"."];
    }

    return keyPath;
}

- (NSArray *) keyPathComponents
{
    NSEnumerator *e = [_keyValue objectEumerator];
    NSArray *component;
    NSMutableArray *keyPath = [NSMutableArray arrayWithCapacity: 10];

    while ((component = [e nextObject]) != nil)
    {
        [keyPath addObject: [component objectAtIndex: 0]];
    }

    return keyPath;
}


- (NSArray *) valuePathComponents
{
    NSEnumerator *e = [_keyValue objectEumerator];
    NSArray *component;
    NSMutableArray *keyPath = [NSMutableArray arrayWithCapacity: 10];

    while ((component = [e nextObject]) != nil)
    {
        int length = [component count] - 1;

        [keyPath addObject: 
            [component subarrayWithRange: NSMakeRange(1, length)]];
    }

    return keyPath;
}

@end
