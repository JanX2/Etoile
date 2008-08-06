/*
	EtoileTunesController.m
	
	Copyright (C) 2008 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  May 2008
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileSerialize/EtoileSerialize.h>
#import <EtoileUI/EtoileUI.h>
#import <CoreObject/CoreObject.h>
#import <IconKit/IconKit.h>

#import "EtoileTunesController.h"
#import "MusicPlayerController.h"
#import "ETAlbum.h"
#import "ETMusicFile.h"
#import "ETPlaylist.h"

static NSString *LIBRARYPATH = nil;
static NSArray *KnownExtensions;

@implementation EtoileTunesController
+ (void) initialize
{
	if (self == [EtoileTunesController class])
	{
		KnownExtensions = [A(@"mp3", @"ogg", @"flac", @"aac", @"m4a") retain];
		LIBRARYPATH = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
				NSUserDomainMask, YES) objectAtIndex:0];
		LIBRARYPATH = 
			[LIBRARYPATH stringByAppendingPathComponent: @"EtoileTunesLibrary"];
		[LIBRARYPATH retain];
	}
}
- (id) deserialize
{
	NSLog(@"Deserializing..");
	ETDeserializer *deserializer = [[ETSerializer serializerWithBackend:[ETSerializerBackendBinary class]
                                                      forURL:[NSURL fileURLWithPath:LIBRARYPATH]] deserializer];
	[deserializer setVersion: 0];
	return [deserializer restoreObjectGraph];
}

- (void) serialize
{
	NSLog(@"Serializing..");
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	ETSerializer *serializer = [ETSerializer serializerWithBackend:[ETSerializerBackendBinary class]
	                                         forURL:[NSURL fileURLWithPath:LIBRARYPATH]];
	[serializer serializeObject:mainModel withName:"library"];
	[pool release];
}

- (id) init
{
	SUPERINIT

	if ([[NSFileManager defaultManager] fileExistsAtPath: LIBRARYPATH])
	{
		mainModel = [self deserialize];
	}
	if (nil == mainModel)
	{
		mainModel = [[ETPlaylist alloc] init];
	}

	playlistModel = [[ETPlaylist alloc] init];
	return self;
}

- (void) dealloc
{
	[mainModel release];
	[playlistModel release];
	[super dealloc];
}

- (void) applicationWillTerminate: (NSNotification *)aNotification
{
	[self serialize];
}

- (void) addFiles: (id)sender;
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setAllowsMultipleSelection: YES];
	[op setCanChooseDirectories: YES];
	[op runModalForTypes: KnownExtensions];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	FOREACH([op filenames], file, NSString *)
	{
		BOOL isDirectory = NO;
		[fm fileExistsAtPath:file isDirectory:&isDirectory];
		if (isDirectory)
		{
			NSDirectoryEnumerator * e = [fm enumeratorAtPath:file];
			NSString *subFile;
			while (nil != (subFile = [e nextObject]))
			{
				if ([KnownExtensions containsObject:[subFile pathExtension]])
				{
					NSLog(@"Adding %@ to playlist..", subFile);
					[mainModel addObject: 
	 				  [[ETMusicFile alloc] initWithPath: 
						[file stringByAppendingPathComponent: subFile]]];

				}
			}
		}
		else
		{
			NSLog(@"Adding %@ to playlist..", file);
			[mainModel addObject: [[ETMusicFile alloc] initWithPath: file]];
		}
	}
	[mainContainer reloadAndUpdateLayout];
}

- (void) addURL: (id)sender
{
	[addURLWindow orderOut: self];
	NSString *string = [[URLTextField stringValue] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	
	[mainModel addObject: [[ETMusicFile alloc] initWithURL:[NSURL URLWithString:string]]];
	[mainContainer reloadAndUpdateLayout];
}

- (void) newPlaylist: (id)sender
{
	COGroup *newPlaylist = [[ETPlaylist alloc] init];
	[newPlaylist addObject:[[ETMusicFile alloc] initWithURL:[NSURL URLWithString: @"http://scfire-chi0l-1.stream.aol.com/stream/1018"]]];
	
	[playlistModel addObject: newPlaylist];

	[playlistContainer reloadAndUpdateLayout];
}

- (void) awakeFromNib
{
	id layoutObject = [ETTableLayout layout];
	
	[layoutObject setDisplayName: @"Title" forProperty: kETTitleProperty];
	[layoutObject setDisplayName: @"Artist" forProperty: kETArtistProperty];
	[layoutObject setDisplayName: @"Album" forProperty: kETAlbumProperty];
	[layoutObject setDisplayName: @"URL" forProperty: kETURLProperty];
	
	[layoutObject setDisplayedProperties:
	    A(@"icon", kETTitleProperty, kETArtistProperty, kETAlbumProperty, kETURLProperty)];

	[mainContainer setSource: [mainContainer layoutItem]];
	[[mainContainer layoutItem] setRepresentedObject: mainModel];
	[mainContainer setLayout: layoutObject];
	[mainContainer setHasVerticalScroller: YES];
	[mainContainer setTarget: self];
	[mainContainer setDoubleAction: @selector(doubleClickInContainer:)];
	[mainContainer reloadAndUpdateLayout];

	[playlistContainer setSource: [playlistContainer layoutItem]];
	[[playlistContainer layoutItem] setRepresentedObject: playlistModel];
	[playlistContainer setLayout: [ETOutlineLayout layout]];
	[playlistContainer setHasVerticalScroller: YES];
	[playlistContainer setTarget: self];
	[playlistContainer setDoubleAction: @selector(doubleClickInContainer:)];
}

- (void) doubleClickInContainer: (id)sender
{
	NSLog(@"Got double-click on %@ in %@", [sender doubleClickedItem], sender);

	[musicPlayerController playObject: [sender doubleClickedItem] start: YES];	
}

@end
