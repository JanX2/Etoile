/*
	ETMusicFile.m
	
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
#import <CoreObject/CoreObject.h>
#import <IconKit/IconKit.h>

#import "ETLastFM.h"
#import "ETMusicFile.h"

NSString *kETURLProperty = @"kETURLProperty";
NSString *kETTitleProperty = @"kETTitleProperty";
NSString *kETArtistProperty = @"kETArtistProperty";
NSString *kETAlbumProperty = @"kETAlbumProperty";
NSString *kETCommentProperty = @"kETCommentProperty";
NSString *kETGenreProperty = @"kETGenreProperty";
NSString *kETYearProperty = @"kETYearProperty";
NSString *kETTrackProperty = @"kETTrackProperty";
NSString *kETLengthProperty = @"kETLengthProperty";
NSString *kETBitrateProperty = @"kETBitrateProperty";
NSString *kETSamplerateProperty = @"kETSamplerateProperty";
NSString *kETChannelsProperty = @"kETChannelsProperty";
NSString *kETPlayingProperty = @"kETPlayingProperty";

@implementation ETMusicFile

+ (void) initialize
{
	[super initialize];

	NSDictionary *pt = [[NSDictionary alloc] initWithObjectsAndKeys:
	    [NSNumber numberWithInt: kCOStringProperty], kETURLProperty,
	    [NSNumber numberWithInt: kCOStringProperty], kETTitleProperty,
	    [NSNumber numberWithInt: kCOStringProperty], kETArtistProperty,
	    [NSNumber numberWithInt: kCOStringProperty], kETAlbumProperty,
	    [NSNumber numberWithInt: kCOStringProperty], kETCommentProperty,
	    [NSNumber numberWithInt: kCOStringProperty], kETGenreProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETYearProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETTrackProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETLengthProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETBitrateProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETSamplerateProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETChannelsProperty,
	    [NSNumber numberWithInt: kCOIntegerProperty], kETPlayingProperty,
	    nil];
	[self addPropertiesAndTypes: pt];

	DESTROY(pt);
}

- (ETMusicFile *) initWithURL: (NSURL *)aURL
{
	SELFINIT
	[self setURL: aURL];
	[self tryStartPersistencyIfInstanceOfClass: [ETMusicFile class]];
	return self;
}

- (ETMusicFile *) initWithPath: (NSString *)aPath
{
	[super initWithPath: aPath];
        [self tryStartPersistencyIfInstanceOfClass: [ETMusicFile class]];
        return self;
}

- (void) setURL: (NSURL *)aURL
{
	[self setValue: [aURL absoluteString]
	   forProperty: kETURLProperty];
}

#define EMPTY_STRING_IF_NIL(obj) ((obj) == nil ? (id)@"" : (id)(obj))

- (void) setPath: (NSString *)path
{
	[super setPath: path];

	[self setValue: [[NSURL fileURLWithPath: path] absoluteString]
	   forProperty: kETURLProperty];

	tag = [[TLMusicFile alloc] initWithPath: path];
	if (tag == nil)
		NSLog(@"Nil tag");

	[self setValue: EMPTY_STRING_IF_NIL([tag title])
	   forProperty: kETTitleProperty];
	[self setValue: EMPTY_STRING_IF_NIL([tag artist])
	   forProperty: kETArtistProperty];
	[self setValue: EMPTY_STRING_IF_NIL([tag album])
	   forProperty: kETAlbumProperty];
	[self setValue: EMPTY_STRING_IF_NIL([tag comment])
	   forProperty: kETCommentProperty];
	[self setValue: EMPTY_STRING_IF_NIL([tag genre])
	   forProperty: kETGenreProperty];
	[self setValue: [NSNumber numberWithInt:[tag year]]
	   forProperty: kETYearProperty];
	[self setValue: [NSNumber numberWithInt:[tag track]]
	   forProperty: kETTrackProperty];
	[self setValue: [NSNumber numberWithInt:[tag length]]
	   forProperty: kETLengthProperty];
	[self setValue: [NSNumber numberWithInt:[tag bitrate]]
	   forProperty: kETBitrateProperty];
	[self setValue: [NSNumber numberWithInt:[tag samplerate]]
	   forProperty: kETSamplerateProperty];
	[self setValue: [NSNumber numberWithInt:[tag channels]]
	   forProperty: kETChannelsProperty];

	NSLog(@"Finished setting ETMusicFile properties from taglib");
	return;
}

- (NSURL *) URL
{
	return [NSURL URLWithString: [self valueForProperty: kETURLProperty]];
}

- (NSString *) name
{
	return [self valueForProperty: kETTitleProperty];
}

- (NSString *) displayName
{
	NSString *display = [self name];
	if (display == nil && [display isEqual: @""])
		display = [[self path] lastPathComponent];
	if (display == nil && [display isEqual: @""])
		display = [self valueForProperty: kETURLProperty];
	return display;
}

- (NSImage *) icon
{
	if ([tag cover] != nil)
		return [tag cover];
	else
		return [[IKIcon iconWithIdentifier: @"audio-x-generic"] image];
}

@end
