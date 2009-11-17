#import "MKMediaFile.h"
#import <EtoileFoundation/EtoileFoundation.h>

// Ugly hack to prevent tag_c.h from redefining BOOL
#define BOOL BOOL
#include <tag_c.h>
#include <mp4.h>

// If we're building for an old version of libavcodec, use the old API
#if LIBAVCODEC_VERSION_INT  < ((52<<16)+(25<<8)+0)
#define avcodec_decode_audio3(context, buffer, bufferSize, pkt) \
	avcodec_decode_audio2(context, buffer, bufferSize, (pkt)->data, (pkt)->size)
#endif

// Metadata keys
static NSString *kETTitleProperty = @"kETTitleProperty";
static NSString *kETArtistProperty = @"kETArtistProperty";
static NSString *kETAlbumProperty = @"kETAlbumProperty";
static NSString *kETCommentProperty = @"kETCommentProperty";
static NSString *kETGenreProperty = @"kETGenreProperty";
static NSString *kETYearProperty = @"kETYearProperty";
static NSString *kETTrackProperty = @"kETTrackProperty";
static NSString *kETLengthProperty = @"kETLengthProperty";
static NSString *kETBitrateProperty = @"kETBitrateProperty";
static NSString *kETSamplerateProperty = @"kETSamplerateProperty";
static NSString *kETChannelsProperty = @"kETChannelsProperty";

@interface MKMediaFile (Metadata)
- (void) readMetadata;
- (BOOL) readAVFormatMetadata;
- (BOOL) readMP4Metadata;
- (BOOL) readTaglibMetadata;
- (BOOL) writeTaglibMetadata;
@end



@implementation MKMediaFile
+ (void) initialize
{
	av_register_all();
}
- (id) initWithURL:(NSURL*) aURL
{
	SELFINIT;
	ASSIGN(URL, aURL);
	NSString *filename = [URL isFileURL] ? [URL path] : [URL absoluteString];
	const char *c_filename = [filename UTF8String];
	if ((av_open_input_file(&formatContext, c_filename, NULL, 0, NULL) != 0)
	    ||
	    (av_find_stream_info(formatContext) < 0))
	{
		[self release];
		return nil;
	}
	[self readMetadata];
#ifdef DEBUG
	dump_format(formatContext, 0, c_filename, NO);
#endif
	return self;
}
- (id) initWithPath:(NSString*) path
{
	return [self initWithURL:[NSURL fileURLWithPath:path]];
}
- (NSURL*) URL
{
	return URL;
}
- (BOOL) setCodec
{
	codec = avcodec_find_decoder(context->codec_id);
	if (codec == NULL)
	{
		NSLog(@"No codec");
		return NO;
	}
	if (codec->capabilities & CODEC_CAP_TRUNCATED)
	{
	    context->flags |= CODEC_FLAG_TRUNCATED;
	}
	// Open codec
	if (avcodec_open(context, codec) < 0) 
	{
		NSLog(@"Open codec failed.");
		return NO;
	}
	return YES;
}
- (BOOL) selectAnyVideoStream
{
	context = NULL;
	for (int i=0 ; i<formatContext->nb_streams ; i++)
	{
		if(formatContext->streams[i]->codec->codec_type==CODEC_TYPE_VIDEO)
		{
			context = formatContext->streams[i]->codec;
			stream = i;
			break;
		}
	}
	return context != NULL && [self setCodec];
}
- (BOOL) selectAnyAudioStream
{
	context = NULL;
	for (int i=0 ; i<formatContext->nb_streams ; i++)
	{
		if(formatContext->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO)
		{
			context = formatContext->streams[i]->codec;
			stream = i;
			break;
		}
	}
	return context != NULL && [self setCodec];
}
- (int) streams
{
	return formatContext->nb_streams;
}
- (BOOL) isAudioFile
{
	for (int i=0 ; i<formatContext->nb_streams ; i++)
	{
		if(formatContext->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO)
		{
			return YES;
		}
	}
	return NO;
}
- (BOOL) isVideoFile
{
	for (int i=0 ; i<formatContext->nb_streams ; i++)
	{
		if(formatContext->streams[i]->codec->codec_type==CODEC_TYPE_VIDEO)
		{
			return YES;
		}
	}
	return NO;
}
- (void) dealloc
{
	if (NULL != formatContext)
	{
		av_close_input_file(formatContext);
	}
	if (NULL != context)
	{
	}
	[super dealloc];
}
- (int) channels
{
	if (NULL == context)
	{
		return 0;
	}
	return context->channels;
}
- (int) sampleRate
{
	if (NULL == context)
	{
		return 0;
	}
	return context->sample_rate;
}
- (int) requiredBufferSize
{
	// FIXME: Should be the size of the next frame or something more sensible
	return AVCODEC_MAX_AUDIO_FRAME_SIZE;
}
- (void) seekTo:(int64_t)milliseconds
{
	AVRational timeBase = formatContext->streams[stream]->time_base;
	int64_t ts = milliseconds * timeBase.den / timeBase.num / 1000;
	av_seek_frame(formatContext, 
			formatContext->streams[stream]->index, 
			ts,
			0);
}
- (int64_t) timestamp
{
	AVRational timeBase = formatContext->streams[stream]->time_base;
	return timestamp * timeBase.num / timeBase.den *1000;
}
- (int64_t) duration
{
	AVRational timeBase = formatContext->streams[stream]->time_base;
	return formatContext->streams[stream]->duration * timeBase.num
		/ timeBase.den *1000;
}
- (int) decodeAudioTo:(int16_t*)buffer size:(int)bufferSize
{
	AVPacket pkt;
	if (av_read_frame(formatContext, &pkt) < 0)
	{
		return -1;
	}
	timestamp = pkt.pts;
	avcodec_decode_audio3(context, buffer, &bufferSize, &pkt);
	av_free_packet(&pkt);
	return bufferSize;
}
- (NSDictionary *)metadata
{
	return metadata;
}
@end


#define GET_CSTRING_TAG(key, value)\
do {\
	const char *str = str;\
	if (str != NULL && *str != '\0')\
	{\
		[metadata setValue: [NSString stringWithUTF8String: str]\
		            forKey: key];\
	}\
} while (0);
#define GET_INT_TAG(key, value)\
	[metadata setValue: [NSNumber numberWithInt: value]\
	            forKey: key];
#define GET_INT64_TAG(key, value)\
	[metadata setValue: [NSNumber numberWithLongLong: value]\
	            forKey: key];

@implementation MKMediaFile (Metadata)

- (void) readMetadata
{
	BOOL success = NO;
	if ([URL isFileURL])
	{
		success = [self readTaglibMetadata];
		if (!success)
		{
			success = [self readMP4Metadata];
		}
	}
	if (!success)
	{
		success = [self readAVFormatMetadata];
	}
}

- (BOOL) readAVFormatMetadata
{
	GET_CSTRING_TAG(kETTitleProperty, formatContext->title)
	GET_CSTRING_TAG(kETArtistProperty, formatContext->author)
	GET_CSTRING_TAG(kETAlbumProperty, formatContext->album)
	GET_CSTRING_TAG(kETCommentProperty, formatContext->comment)
	GET_CSTRING_TAG(kETGenreProperty, formatContext->genre)
	GET_INT_TAG(kETYearProperty, formatContext->year)
	GET_INT_TAG(kETTrackProperty, formatContext->track)
	GET_INT64_TAG(kETLengthProperty, ((formatContext->duration * 1000) / AV_TIME_BASE))
	return YES;
}

#define MP4_GET_STRING(key, name) if(MP4GetMetadata ## name(hFile, &value))\
{\
	GET_CSTRING_TAG(key, value)\
}
- (BOOL) readMP4Metadata
{
	MP4FileHandle hFile = MP4Read([[URL path] UTF8String], 0);
	if(MP4_INVALID_FILE_HANDLE == hFile)
	{
		return NO;
	}
	char *value = NULL;
	MP4_GET_STRING(kETTitleProperty, Name)
	MP4_GET_STRING(kETArtistProperty, Artist)
	MP4_GET_STRING(kETAlbumProperty, Album)
	MP4_GET_STRING(kETCommentProperty, Comment)
	MP4_GET_STRING(kETGenreProperty, Genre)

	if (MP4GetMetadataYear(hFile, &value))
	{
		[metadata setValue: [NSNumber numberWithLong: strtol(value, NULL, 10)]
		            forKey: kETYearProperty];
	}
	u_int16_t track, totalTracks;
	if (MP4GetMetadataTrack(hFile, &track, &totalTracks))
	{
		[metadata setValue: [NSNumber numberWithInt: track]
		            forKey: kETTrackProperty];
	}

	/* Album cover extraction from MP4's is disabled for now. We don't do much
	   with them, and the MP4GetMetadataCoverArt function will cause a compile 
	   error for people with old versions of the MP4 library.
	
	u_int32_t imageLength;
	u_int8_t *image;
	if (MP4GetMetadataCoverArt(hFile, &image, &imageLength, 0))
	{
		NSImage *cover = [[NSImage alloc] initWithData:
			[NSData dataWithBytes: image length: imageLength]];
	} */

	MP4Close(hFile);
	return YES;
}
				
- (BOOL) readTaglibMetadata
{
	TagLib_File *tlfile = taglib_file_new([[URL path] UTF8String]);
	/* 
	 * TODO: Currently, invalid files don't return a NULL tlfile.
	 * They're supposed to. Trying to read e.g. the title then segfaults.
	 * 
	 * The taglib_file_is_valid was recently added to the TagLib C binding,
	 * which should fix the problem.
	 */
	if (tlfile == NULL)// || !taglib_file_is_valid(tlfile))
	{
		return NO;
	}

	TagLib_Tag *tltag = taglib_file_tag(tlfile);
	const TagLib_AudioProperties *tlprops = taglib_file_audioproperties(tlfile);
	
	GET_CSTRING_TAG(kETTitleProperty, taglib_tag_title(tltag))
	GET_CSTRING_TAG(kETArtistProperty, taglib_tag_artist(tltag))
	GET_CSTRING_TAG(kETAlbumProperty, taglib_tag_album(tltag))
	GET_CSTRING_TAG(kETCommentProperty, taglib_tag_comment(tltag))
	GET_CSTRING_TAG(kETGenreProperty, taglib_tag_genre(tltag))
	GET_INT_TAG(kETYearProperty, taglib_tag_year(tltag))
	GET_INT_TAG(kETTrackProperty, taglib_tag_track(tltag))
	GET_INT64_TAG(kETLengthProperty, 1000*(int64_t)taglib_audioproperties_length(tlprops))
	GET_INT_TAG(kETBitrateProperty, taglib_audioproperties_bitrate(tlprops))
	GET_INT_TAG(kETSamplerateProperty, taglib_audioproperties_samplerate(tlprops))
	GET_INT_TAG(kETChannelsProperty, taglib_audioproperties_channels(tlprops))

	taglib_file_free(tlfile);
	taglib_tag_free_strings();
	return YES;
}

#define SET_STRING_TAGLIB_TAG(name, key)\
if([metadata valueForKey: key] != nil && \
   [metadata valueForKey: key] != @"")\
{\
	taglib_tag_set_ ## name(tltag, [[metadata valueForKey: key] UTF8String]);\
}
#define SET_INT_TAGLIB_TAG(name, key)\
if([metadata valueForKey: key] != nil)\
{\
	taglib_tag_set_ ## name(tltag, [[metadata valueForKey: key] intValue]);\
}
/**
 * Currently not public
 */
- (BOOL) writeTaglibMetadata
{
	BOOL success = NO;
	if ([URL isFileURL])
	{
		TagLib_File *tlfile;
		TagLib_Tag *tltag;

		tlfile = taglib_file_new([[URL path] UTF8String]);
		if (tlfile == NULL)
			return NO;

		tltag = taglib_file_tag(tlfile);
		SET_STRING_TAGLIB_TAG(title, kETTitleProperty)
		SET_STRING_TAGLIB_TAG(artist, kETArtistProperty)
		SET_STRING_TAGLIB_TAG(album, kETAlbumProperty)
		SET_STRING_TAGLIB_TAG(comment, kETCommentProperty)
		SET_STRING_TAGLIB_TAG(genre, kETGenreProperty)
		SET_INT_TAGLIB_TAG(year, kETYearProperty)
		SET_INT_TAGLIB_TAG(track, kETTrackProperty)

		// FIXME: lock the file somehow
		success = taglib_file_save(tlfile);
		taglib_file_free(tlfile);
	}
	return success;
}

@end
