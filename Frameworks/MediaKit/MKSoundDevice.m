#import "MKSoundDevice.h"
@class OSSDevice;
Class OSSDeviceClass;
@implementation SoundService
+ (void) initialize
{
	OSSDeviceClass = [OSSDevice class];
}
+ (Class) defaultAudioDevice
{
	return OSSDeviceClass;
}
@end 

