/*
	TKStructuralKey.h

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

@interface TKStructuralKey : NSObject // Light ordered dictionary
{
  NSMutableArray *_structuralKey;
  NSString *_identifier
}

- (id) initWithIdentifier: (NSString *)identifier;
- (id) initWithIdentifier: (NSString *)identifier 
      structuralKeyString: (NSString *)structuralKeyString; // not implemented

/*
Structural key syntax

Example :
(town = {"*York", "Helsinki"}).(street = "*").(door = {"1", "+2?", "4})

Supported metacharacters in the current state : *
*/

- (void) addValue: (NSString *)value forKeyComponent: (NSString *)keyComponent;
- (void) addValuesArray: (NSArray *)valuesArray 
        forKeyComponent: (NSString *)keyComponent; // not implemented
- (NSArray *) componentAtIndex: (unsigned int)index; // not implemented
- (NSString *) identifier;
- (NSArray *) structuralKey;
- (NSString *) structuralKeyString; // not implemented -- called by description method

@end