/*
	TKTracker.h

	TKTracker is the TrackerKit core class which is used to handle track sessions

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

@interface TKTracker : NSObject 
// Like KVC with variables content (not with the variables name like traditional
// KVC)
{
  NSMutableArray *structuralKeys;
  NSMutableDictionary *objectsSoup;
  NSMutableDictionary *trackingStructure;
  BOOL renewTrack;
}

/*

class TKToolbar
- class
- identifier

object TKToolbar
- class : TKToolbar
- identifier : "John"

object 1
- class : TKToolbar
- identifier : "John"

object 2
- class : TKToolbar
- identifier : "Michael"

object 3
- class : NSToolbar
- identifier : "Michael"

object 4
- class : NSToolbar
- identifier : "Will"

object 5
- class : NSToolbar
- identifier : "Michael"

For structural key "class.identifier", the resulting tracker structure is :

{
  TKToolbar = 
  {
     John = object 1;
     Michael = object 2;
  };
  NSToolbar = 
  {
     Michael = 
     {
       object 3;
       object 5;
     };
     Will = object 4;
  };
};


*/

+ (void) setArchiveDefault; // not implemented
+ (void) setArchiveUseTrackers: (NSArray *)trackers 
            withStructuralKeys: (NSArray *)structuralKeys; // not implemented
// something like + (NSData *) archive;

/*
With the method setArchiveUseTrackers:withStructuralKeys:, each tracker tracked 
objects are merged in one dictionnary (using isEqual: to do the merge), which is
saved at the start of the archive. Tracked objects in the first part of the 
archive (the encoded dictionary) are identified by an id. The rest of the 
archive stores the hierachical structures for the structural keys referring to
the tracked objects by their id.
*/

- (id) initWithStructuralKey: (TKStructuralKey *)structuralKey;

- (TKTracker *) trackerWithStructuralKey: (TKStructuralKey *)structuralKey; 
// not implemented

- (TKStructuralKey *) structuralKey;
- (void) trackObject: (id)object;
- (void) _trackObject: (id)object 
     forStructuralKey: (TKStructuralKey *)structuralKey;
- (id) objectForStructuralKey: (TKStructuralKey *)structuralKey;

@end
