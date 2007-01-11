/*
	TKTracker.m

	TKtracker is the TrackerKit core class which is used to handle track sessions

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
#import "TKTracker.h"

@implementation TKTracker 
// Like KVC with variables content (not with the variables name like traditional
// KVC)

+ (void) setArchiveDefault
{
  // not implemented
}

+ (void) setArchiveUseTrackers: (NSArray *)trackers 
            withStructuralKeys: (NSArray *)structuralKeys
{
  // not implemented
}

- (id) initWithStructuralKey: (TKStructuralKey *)structuralKey
{
  if ((self = [super init]) != nil)
    {
      renewTrack = NO;
      [self addStructuralKey: structuralKey];
      return self;
    }
    
  return nil;
}

- (TKTracker *) trackerWithStructuralKey: (TKStructuralKey *)structuralKey
{
  // not implemented
}

- (void) addStructuralKey: (TKStructuralKey *)structuralKey
{
  NSMutableDictionary *node = [NSMutableDictionary dictionary];
  
  [structuralKeys addObject: structuralKey];
  
  // Instantiate the associated structural structure
  [trackinTKtructures setValue: node forKey: [structuralKey identifier]];
  [self _buildTrackinTKtructureElement: node 
            withStructuralKeyStructure: [structuralKey structuralKeyStructure]
	       structuralKeyStructureIndex: 0];

}

- (void) _buildTrackinTKtructureElement: (id)node 
             withStructuralKeyStructure: (NSArray *)structuralKeyStructure
	        structuralKeyStructureIndex: (unsigned int) index
{
  id component; 
  int i, n;
  
  if (index < [structuralKeyStructure count])
    {
      component = [structuralKeyStructure objectAtIndex: index];
    }
  else
    {
      return;
    }
  
  n = [component count];
  for (i = 1; i < n; i++)
    {
      dict = [NSMutableDictionary dictionary]:
      
      [self _buildTrackinTKtructureElement: dict 
                withStructuralKeyStructure: structuralKeyStructure
	           structuralKeyStructureIndex: ++index];
      [node setValue: dict forKey: [component objectAtIndex: i];
    }
}

- (NSArray *) structuralKeys
{
  return structuralKeys;
}

// should return TKMatchStructuralKey

- (void) stopTrackObject:(id)object
{
  id node;
  
  node = [trackinTKtructure valueForKey: [structuralKey keyPath]];
  [node removeObject: [self _refForObject: object]];
  
  if (!renewTrack)
    [objectsSoup removeObject: object];
}

- (void) trackObject: (id)object
{
  NSEnumerator *e = [structuralKeys objectEnumerator];
  id structuralKey; 
    
  if (!renewTrack)  
    [objectsSoup setValue: object forKey: [self _refForObject: object]];
  
  while ((structuralKey = [e nextObject]) != nil)
    {
      [self _trackObject: object forStructuralKey: structuralKey];
    }
}

- (void) _trackObject: (id)object 
     forStructuralKey: (TKStructuralKey *)structuralKey
{
  NSObjectEnumerator *e = 
    [[structuralKey structuralKeyStructure] objectEnumerator];
  id component;
  id keyComponent;
  int i, n;
  id node;
  
  while ((component = [e nextObject]) != nil)
    {
      keyComponent = [component objectAtIndex: 0];
      
      
      if ([component containsObject: @"*"])
        {
          [self _referenceObject: object 
            inTrackinTKtructureWithStructuralKey: structuralKey];
	}
      else
        {
          value = [object valueForKey: keyComponent];
          n = [component count];
          for (i = 1; i < n; i++)
            {
              if ([value isEqual: [component objectAtIndex: i]])
	        {
                  [self _referenceObject: object 
                    inTrackinTKtructureWithStructuralKey: structuralKey];
	        }
	    }
        }
	
    }
    
}

- (void) _referenceObject: (id)object 
  inTrackinTKtructureWithStructuralKey: (TKStructuralKey *)structuralKey
{
  id node;
  
  node = [trackinTKtructure valueForKey: [structuralKey keyPath]];
  [node addObject: [self _refForObject: object]];
}

- (id) _refForObject: (id)object
{
  return [object hash];
}

- (id) objectForStructuralKey: (TKStructuralKey *)structuralKey
{
  return [trackinTKtructure valueForKey: [structuralKey keyPath]];
}

- (void) renewTrackObject: (id)object
{
  renewTrack = YES;
  
  [self stopTrackObject: object];
  [self trackObject: object];
  
  renewTrack = NO;
}

@end
