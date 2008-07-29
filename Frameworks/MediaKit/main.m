#import "MKMusicPlayer.h"
#include <unistd.h>

int main(int argc, char **argv)
{
	[NSAutoreleasePool new];
	MKMusicPlayer *player = [[MKMusicPlayer alloc] initWithDefaultDevice];
	// Move the player into a new thread.
	player = [player inNewThread];
	// Add any files specified on the command line.
	for (int i=1 ; i<argc ; i++)
	{
		NSString * filename = [NSString stringWithCString:argv[i]];
		NSLog(@"Adding file: %@", filename);
		[player addFile:filename];
	}
	// Seek near the end of the file so that we can check multiple files work...
	[player seekTo:350000];
	[player setVolume:100];
	// Begin playing
	[player play];

	// Periodically wake up and see where we are.
	while (1)
	{
		id pool = [NSAutoreleasePool new];
		sleep(2);
		NSLog(@"Playing %@ at %lld/%lld", [player currentFile], [player currentPosition] / 1000, [player duration] / 1000);
		[pool release];
	}
	return 0;
}	
