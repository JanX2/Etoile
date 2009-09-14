/** <title>ETMailAccount</title>
 
	<abstract></abstract>
	
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  September 2009
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <Pantomime/Pantomime.h>

@interface ETMailAccount : NSObject <ETCollection, ETPropertyValueCoding>
{
	CWService <CWStore> *_service;
	NSMutableDictionary *_properties;
	NSMutableDictionary *_folders;
}

- (void) reconnect;

@end
