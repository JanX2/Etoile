#import <Foundation/NSObject.h>
#import "MKSoundDevice.h"

@interface OSSDevice : NSObject<MKSoundDevice> {
	int dev;
}
@end
