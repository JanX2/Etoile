/*
	TKStructuralKey.m

	TKStructuralKey is the TrackerKit class used to encode the special keys which
	drive track sessions
	
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
#import "TKStructuralKey.h"

@implementation TKStructuralKey // Light ordered dictionary

- (id) initWithIdentifier: (NSString *)identifier
{
  if ((self = [super init]) != nil)
    {
       ASSIGN(_identifier, identifier);
       _structuralKey = [[NSMutableArray alloc] init];
       
       return self;
    }
    
  return nil;
}

- (id) initWithIdentifier: (NSString *)identifier 
      structuralKeyString: (NSString *)structuralKeyString 
{
  // not implemented
} 

- (void) dealloc
{
  [_structuralKey release];
}

- (void) addValue: (NSString *)value forKeyComponent: (NSString *)keyComponent
{
  NSArray *component;
  
  if (keyComponent == nil)
    [NSException raise: NSInvalidArgumentException
                format: @"Nil keyComponents aren't valid."];
  component = [NSArray arrayWithObjects: keyComponent, value];
  [_structuralKey addObject: component];
}

- (void) addValuesArray: (NSArray *)valuesArray 
        forKeyComponent: (NSString *)keyComponent;
{
  // not implemented
}

- (NSString *) identifier
{
  return _identifier;
}

- (NSArray *) componentAtIndex: (unsigned int)index
{
  // not implemented
}

- (NSString *) keyPath
{
  
}

- (NSArray *) structuralKeyStructure
{
  return _structuralKey;
}

- (NSString *) structuralKeyString
{
  // not implemented -- called by description method
}

@end
