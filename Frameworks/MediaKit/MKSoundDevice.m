#import "MKSoundDevice.h"
@interface OSSDevice : NSObject<MKSoundDevice>
@end
Class  OSSDeviceClass;
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

