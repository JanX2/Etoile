/*
	TLMusicFile.m
	
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

#import <EtoileFoundation/EtoileFoundation.h>

#include <tag_c.h>
#include <mp4.h>
#import "TLMusicFile.h"

@implementation TLMusicFile

#define MP4_GET_STRING(var, name) if(MP4GetMetadata ## name(hFile, &value))\
{\
	ASSIGN(var, [NSString stringWithUTF8String:value]);\
}
#define MP4_GET_INT(var, name) if(MP4GetMetadata ## name(hFile, &value2))\
{\
	var = (int)value2;\
}
- (BOOL) mp4ReadTagsForFile: (NSString*) aPath
{
	MP4FileHandle hFile = MP4Read([aPath UTF8String], 0);
	if(MP4_INVALID_FILE_HANDLE == hFile)
	{
		return NO;
	}
	char *value = NULL;
	MP4_GET_STRING(album, Album)
	MP4_GET_STRING(title, Name)
	MP4_GET_STRING(artist, Artist)
	MP4_GET_STRING(comment, Comment)
	MP4_GET_STRING(genre, Genre)

	if (MP4GetMetadataYear(hFile, &value))
	{
		year = strtol(value, NULL, 10);
	}
	MP4GetMetadataTrack(hFile, &track, &totalTracks);
	return YES;
}
- (BOOL) taglibReadTagsForFile:(NSString*) aPath
{
	TagLib_File *tlfile;
	TagLib_Tag *tltag;
	const TagLib_AudioProperties *tlprops;

	tlfile = taglib_file_new([aPath UTF8String]);

	/* 
	 * TODO: Currently, invalid files don't return a NULL tlfile.
	 * They're supposed to. Trying to read e.g. the title then segfaults.
	 * 
	 * The taglib_file_is_valid was recently added to the TagLib C binding,
	 * which should fix the problem.
	 */
	if (tlfile == NULL)// || !taglib_file_is_valid(tlfile))
	{
		NSLog(@"No tags on %@", aPath);
		return NO;
	}

	tltag = taglib_file_tag(tlfile);
	tlprops = taglib_file_audioproperties(tlfile);

	ASSIGN(title, [NSString stringWithUTF8String: taglib_tag_title(tltag)]);
	ASSIGN(artist, [NSString stringWithUTF8String: taglib_tag_artist(tltag)]);
	ASSIGN(album, [NSString stringWithUTF8String: taglib_tag_album(tltag)]);
	ASSIGN(comment, [NSString stringWithUTF8String: taglib_tag_comment(tltag)]);
	ASSIGN(genre, [NSString stringWithUTF8String: taglib_tag_genre(tltag)]);

	year = taglib_tag_year(tltag);
	track = taglib_tag_track(tltag);
	// FIXME: These are accessed more accurately by MediaKit and shouldn't be
	// here:
	length = taglib_audioproperties_length(tlprops);
	bitrate = taglib_audioproperties_bitrate(tlprops);
	samplerate = taglib_audioproperties_samplerate(tlprops);
	channels = taglib_audioproperties_channels(tlprops);

	taglib_file_free(tlfile);
	taglib_tag_free_strings();
	return YES;
}
- (id) initWithPath: (NSString*) aPath
{
	SELFINIT;
	if (![self taglibReadTagsForFile:aPath] && ![self mp4ReadTagsForFile:aPath])
	{
		[self release];
		return nil;
	}
	ASSIGN(path, aPath);
	return self;
}

- (void) dealloc
{
	[path release];
	[title release];
	[artist release];
	[album release];
	[comment release];
	[genre release];
	[super dealloc];
}

- (int) write
{
	BOOL success;
	TagLib_File *tlfile;
	TagLib_Tag *tltag;

	tlfile = taglib_file_new([path UTF8String]);
	if (tlfile == NULL)
		return NO;

	tltag = taglib_file_tag(tlfile);
	taglib_tag_set_title(tltag, [title UTF8String]);
	taglib_tag_set_artist(tltag, [artist UTF8String]);
	taglib_tag_set_album(tltag, [album UTF8String]);
	taglib_tag_set_comment(tltag, [comment UTF8String]);
	taglib_tag_set_genre(tltag, [genre UTF8String]);
	taglib_tag_set_year(tltag, year);
	taglib_tag_set_track(tltag, track);

	success = taglib_file_save(tlfile);
	taglib_file_free(tlfile);
	return success;
}

- (NSString*) title
{
	return title;
}

- (void) setTitle: (NSString*) newTitle
{
	ASSIGN(title, newTitle);
}

- (NSString*) artist
{
	return artist;
}

- (void) setArtist:(NSString*) newArtist
{
	ASSIGN(artist, newArtist);
}

- (NSString*) album
{
	return album;
}

- (void) setAlbum: (NSString*) newAlbum
{
	ASSIGN(album, newAlbum);
}

- (NSString*) comment
{
	return comment;
}

- (void) setComment: (NSString*) newComment
{
	ASSIGN(comment, newComment);
}

- (NSString*) genre
{
	return genre;
}

- (void) setGenre: (NSString*) newGenre
{
	ASSIGN(genre, newGenre);
}

- (int) year
{
	return year;
}

- (void) setYear: (int) newYear
{
	year = newYear;
}

- (int) track
{
	return track;
}

- (void) setTrack: (int) newTrack
{
	track = newTrack;
}

- (int) length
{
	return length;
}

- (int) bitrate
{
	return bitrate;
}

- (int) samplerate
{
	return samplerate;
}

- (int) channels
{
	return channels;
}

@end


