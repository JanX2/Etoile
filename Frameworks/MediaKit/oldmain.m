#import "oss.h"
#import <EtoileFoundation/EtoileFoundation.h>
#include <avcodec.h>
#include <avformat.h>

int main(int argc, char **argv)
{
	OSSDevice *speaker = [[OSSDevice alloc] initForOutput];
	char * filename = argv[1];
	av_register_all();
	AVFormatContext *FormatCtx;
	if(av_open_input_file(&FormatCtx, filename, NULL, 0, NULL)!=0) {}
	if(av_find_stream_info(FormatCtx)<0) {}
	dump_format(FormatCtx, 0, filename, NO);
	AVCodecContext *context = NULL;
	for (int i=0 ; i<FormatCtx->nb_streams ; i++)
	{
		if(FormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO)
		{
			context = FormatCtx->streams[i]->codec;
			break;
		}
	}
	if (context == NULL) {}
	AVCodec *codec = avcodec_find_decoder(context->codec_id);
	if (codec == NULL) {}

	if(codec->capabilities & CODEC_CAP_TRUNCATED)
		    context->flags |= CODEC_FLAG_TRUNCATED;

	// Open codec
	if (avcodec_open(context, codec) < 0) {}

	[speaker setChannels:context->channels];
	[speaker setRate:context->sample_rate];
	[speaker setVolumeLeft:100 right:100];
	AVPacket pkt;
	while(av_read_frame(FormatCtx, &pkt) == 0)
	{
		int bufferSize = AVCODEC_MAX_AUDIO_FRAME_SIZE;
		int16_t buffer[AVCODEC_MAX_AUDIO_FRAME_SIZE];
	NSLog(@"Decoding %d to %d", pkt.size, bufferSize);
		avcodec_decode_audio2(context, buffer, &bufferSize, pkt.data, pkt.size);
		//NSLog(@"Pkt:%lld.  Sample: %hx (%d)", pkt.pts, buffer[0], bufferSize);
		[speaker playSample:buffer count:bufferSize];
	}
	return 0;
}	
