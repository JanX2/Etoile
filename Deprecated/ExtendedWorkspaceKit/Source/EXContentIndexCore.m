/*
	EXContentIndexCore.m

	Full text search related class which provides content indexing support

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Created:  August 2004

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
#import <AppKit/AppKit.h>
#import "EXVFS.h"
#import "EXContext.h"
#import "EXWorkspace.h"

static EXContentIndexCore *sharedInstance = nil;
static EXVFS *vfs = nil;

@implementation EXContentIndexCore

// Basic methods

+ (EXContentIndexCore *) sharedInstance
{
  	if (sharedInstance == nil)
    	{
      		if (AttributesBackend == RDF)
        	{
          		sharedInstance = [EXContentIndexCore alloc]; // Will be something like EXNamazuContentIndexCore
        	}
      		else
        	{
          		sharedInstance = [EXContentIndexCore alloc];
	    	}     
      		sharedInstance = [sharedInstance init];
    	}
    
  	return sharedInstance;      
}

- (id) init
{
  	if (sharedInstance != self)
    	{
      	RELEASE(self);
      	return RETAIN(sharedInstance);
    	}
  
  	if ((self = [super init])  != nil)
    	{
      	vfs = [EXVFS sharedInstance];
    	}
  
  	return self;
}

// Indexation related methods

- (void) indexContext: (EXContext *)context deep: (BOOL)flag // Includes subcontexts indexing when flag is YES
{
    	[self subclassResponsability: _cmd];
}

- (void) indexAtPath: (NSString *)path update:  (BOOL)flag // Includes subpaths
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes
{
    	[self subclassResponsability: _cmd];
}

- (void) indexAtURL: (NSURL *)url update:  (BOOL)flag // Includes subURLs
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes
{
    	[self subclassResponsability: _cmd];
}

@end
