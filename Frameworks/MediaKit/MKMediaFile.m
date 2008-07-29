#import "MKMediaFile.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation MKMediaFile
+ (void) initialize
{
	av_register_all();
}
- (id) initWithFile:(NSString*) file
{
	SELFINIT;
	const char *filename = [file UTF8String];
	if ((av_open_input_file(&formatContext, filename, NULL, 0, NULL) != 0)
	    ||
	    (av_find_stream_info(formatContext) < 0))
	{
		[self release];
		return nil;
	}
#ifdef DEBUG
	dump_format(formatContext, 0, filename, NO);
#endif
	return self;
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
	avcodec_decode_audio2(context, buffer, &bufferSize, pkt.data, pkt.size);
	return bufferSize;
}
@end
