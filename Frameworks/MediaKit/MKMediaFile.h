#import <Foundation/NSObject.h>

// Make sure that the AVCodec things are void* in files that haven't included
// the avcodec header.
#ifndef LIBAVCODEC_VERSION
#define AVFormatContext void
#define AVCodecContext void
#define AVCodecContext void
#endif

@class NSURL, NSMutableDictionary;
/**
 * Class encapsulating a media file.  Currently a fairly minimal implementation
 * which is only capable of accessing a single stream from a file.  Still to do
 * is a mechanism for accessing multiple streams in a file and for decoding
 * video.
 */
@interface MKMediaFile : NSObject {
	AVFormatContext *formatContext;
	AVCodecContext *context;
	AVCodec *codec;
	int stream;
	int64_t timestamp;
	NSURL *URL;
	NSMutableDictionary *metadata;
}
/**
 * Initialises the object with a (potentially remote) media file.
 */
- (id) initWithURL:(NSURL*) aURL;
/**
 * Initialises the object with a media file.
 */
- (id) initWithPath:(NSString*) path;
/**
 * Return the URL of this media file
 */
- (NSURL*) URL;
/**
 * Selects a video stream for playback.  Returns YES if a video stream is found.
 */
- (BOOL) selectAnyVideoStream;
/**
 * Selects any audio stream for playback.  Returns YES if an audio stream is
 * found.
 */
- (BOOL) selectAnyAudioStream;
/**
 * Returns the number of streams in this file.
 */
- (int) streams;
/**
 * Returns YES if this file contains any audio streams.
 */
- (BOOL) isAudioFile;
/**
 * Returns yes if this file contains any video streams.
 */
- (BOOL) isVideoFile;
/**
 * Returns the number of channels in the currently-selected audio stream.
 */
- (int) channels;
/**
 * Returns the sample rate of the currently-selected audio stream.
 */
- (int) sampleRate;;
/**
 * Seek a specified number of milliseconds into the stream.
 */
- (void) seekTo:(int64_t)milliseconds;
/**
 * Returns the current stream position, in milliseconds.
 */
- (int64_t) timestamp;
/**
 * Returns the duration of the currently selected stream, in milliseconds.
 */
- (int64_t) duration;
/**
 * Returns the size of the output buffer required for decoding a frame in the
 * current stream.
 */
- (int) requiredBufferSize;
/**
 * Decodes the next frame of audio to the specified buffer, or a negative
 * result in case of error (e.g. the end of the stream).
 */
- (int) decodeAudioTo:(int16_t*)buffer size:(int)bufferSize;
/**
 * Returns a dictionary of metadata
 */
- (NSDictionary *)metadata;
@end

#ifndef LIBAVCODEC_VERSION
#undef AVFormatContext 
#undef AVCodecContext
#undef AVCodecContext
#endif
