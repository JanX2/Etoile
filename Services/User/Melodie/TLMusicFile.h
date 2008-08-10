/*
	TLMusicFile.h
	
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
#import <AppKit/AppKit.h>

@interface TLMusicFile : NSObject
{
	BOOL hasCover; // FIXME: hack to know whether we should try to load a cover upon deserialization
	NSImage *cover;
	NSString *path;
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *comment;
	NSString *genre;
	uint16_t year;
	uint16_t track;
	uint16_t totalTracks;
	uint16_t length;
	uint16_t bitrate;
	uint16_t samplerate;
	uint16_t channels;
}

- (id) initWithPath: (NSString *)path;
- (int) write;

- (NSImage *) cover;
- (NSString *) title;
- (void) setTitle: (NSString *)title;
- (NSString *) artist;
- (void) setArtist: (NSString *)artist;
- (NSString *) album;
- (void) setAlbum: (NSString *)album;
- (NSString *) comment;
- (void) setComment: (NSString *)comment;
- (NSString *) genre;
- (void) setGenre: (NSString *)genre;
- (int) year;
- (void) setYear: (int) year;
- (int) track;
- (void) setTrack: (int) track;
- (int) length;
- (int) bitrate;
- (int) samplerate;
- (int) channels;

@end
